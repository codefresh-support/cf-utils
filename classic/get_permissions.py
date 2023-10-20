#!/usr/bin/env python3
'''
Script to display users permissions on a set of pipelines
'''

import os
import sys
import json
import logging
import urllib.parse
import requests

CF_URL      = os.getenv('CF_URL', 'https://g.codefresh.io')
CF_API_KEY  = os.getenv('CF_API_KEY')
LOG_LEVEL   = os.getenv('LOG_LEVEL', "error")

#######################################################################

def main():
    '''main function'''
    log_format = "%(asctime)s:%(levelname)s:%(name)s.%(funcName)s: %(message)s"
    logging.basicConfig(format = log_format, level = LOG_LEVEL.upper())

    if CF_API_KEY is None:
        logging.error("CF_API_KEY is not set")
        sys.exit(1)
    teams=get_teams()
    pipelines=get_pipelines(sys.argv)
    abac=get_permissions(teams)

    if LOG_LEVEL == 'debug':
        print_teams(teams)
        print_pipelines (pipelines)
        print_abac(abac)

    process_data(pipelines,abac,teams)

def print_teams(teams):
    '''display list of teams in the account and their users - debug mode'''
    print()
    print("TEAMS:")
    print("------")
    for key in teams.keys():
        print (teams[key]['name'], ":", key, "-", teams[key]['users'])

def print_pipelines(pipelines):
    '''display pipelines and their tags - debug mode'''
    print()
    print("PIPELINES:")
    print("----------")
    for key in pipelines.keys():
        print(key, ":", pipelines[key])

def print_abac(rules):
    '''dislay permissions rules - debug mode'''
    print()
    print("ABAC:")
    print("-----")
    for tag in rules.keys():
        print ("  ", tag)
        for action in rules[tag].keys():
            print("    ",action,"->",rules[tag][action])


def process_data(pipelines,abac,teams):
    '''Print the list of pipelines and the permission for each tag
        and the users involved'''
    logging.info("Entering process_data")

    for pipeline_name in pipelines.keys():
        print(pipeline_name)
        any_tag=False
        for tag in pipelines[pipeline_name]:
            if tag in abac.keys():
                print_users(tag,abac,teams)
            else:
                if any_tag is False and '*' in abac.keys():
                    print_users("*",abac,teams)
                    any_tag=True
                elif any_tag is True:
                    logging.info("Already process any tags rule for this pipeline")

def print_users(tag, abac, teams):
    '''display users permission for a specific tag'''
    logging.info("Entering print_users: %s", tag)
    print ("  ", tag)
    for action in abac[tag].keys():
        team_id= abac[tag][action]
        print (f"    {action}: {teams[team_id]['users']}")


def get_permissions(teams):
    '''Extract permissions rules using API'''
    logging.info("Entering get_permissions")
    url = CF_URL + '/api/abac'
    resp=requests.get(url,
        headers = {"content-type":"application/json",
                   "Authorization": CF_API_KEY})
    if resp.status_code not in [200, 201]:
        logging.error("API call to get permissions failed with code %s",resp.status_code)
        logging.error("Error: %s", resp.text)
        sys.exit(resp.status_code)
    data=resp.json()

    rules={}
    for rule in data:

        if rule['resource'] != 'pipeline':
            logging.info ("Skipping ABAC rule for %s", rule['resource'])
            continue
        if 'attributes' in rule:
            for tag in rule['attributes']:
                # Skip context rules
                if rule['role'] in teams:
                    if tag not in rules:
                        rules[tag]={}
                    rules[tag][rule['action']]=rule['role']
        else:
            logging.info("we have a ANY rule")
            # To be implemented
    return rules

def get_pipelines(pipeline_list):
    '''Extract pipeline atgs using API'''
    logging.info("Entering get_pipelines")
    url = CF_URL + '/api/pipelines/'

    pipelines={}
    for i in range(1,len(pipeline_list)):
        pipeline_name=pipeline_list[i]
        logging.info ("Processing pipeline %s", pipeline_name)
        encoded_pipeline_name=urllib.parse.quote_plus(pipeline_name)
        resp=requests.get(url + encoded_pipeline_name,
            headers = {"content-type":"application/json",
                       "Authorization": CF_API_KEY})
        if resp.status_code not in [ 200, 201]:
            logging.error("API call to get pipeline %s failed with code %s",
                pipeline_name,resp.status_code)
            logging.error("Error: %s", resp.text)
            sys.exit(resp.status_code)
        data=resp.json()
        if 'labels' in data['metadata']:
            tags=data['metadata']['labels']['tags']
        else:
            tags=['untagged']
        pipelines[pipeline_name]=tags
    return pipelines

def get_teams():
    '''Get the list of teams from the API'''
    logging.info("Entering get_teams")
    url = CF_URL + '/api/team'

    resp=requests.get(url,
        headers = {"content-type":"application/json",
                   "Authorization": CF_API_KEY})
    if resp.status_code not in  [200, 201]:
        logging.error("API call to get teams failed with code %s", resp.status_code)
        logging.error("Error: %s", resp.text)
        sys.exit(resp.status_code)

    data=resp.json()
    teams={}
    for team in data:
        team_name = team['name']
        team_id   = team['_id']
        logging.info ("Processing team %s", team_name)
        teams[team_id]={}
        teams[team_id]['name']=team_name
        teams[team_id]['users']=[]
        for user in team['users']:
            teams[team_id]['users'].append(user['userName'])

    return teams

if __name__ == "__main__":
    main()
