import os
import sys
import json
import requests
import logging
import urllib.parse

CF_URL      = os.getenv('CF_URL', 'https://g.codefresh.io')
CF_API_KEY  = os.getenv('CF_API_KEY')
LOG_LEVEL   = os.getenv('LOG_LEVEL', "error")

#######################################################################

def main():
    log_format = "%(asctime)s:%(levelname)s:%(name)s.%(funcName)s: %(message)s"
    logging.basicConfig(format = log_format, level = LOG_LEVEL.upper())

    if CF_API_KEY == None:
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
    print()
    print("TEAMS:")
    print("------")
    for key in teams.keys():
        print (teams[key]['name'], ":", key, "-", teams[key]['users'])

def print_pipelines(pipelines):
    print()
    print("PIPELINES:")
    print("----------")
    for key in pipelines.keys():
        print(key, ":", pipelines[key])

def print_abac(rules):
    print()
    print("ABAC:")
    print("-----")
    for tag in rules.keys():
        print ("  ", tag)
        for action in rules[tag].keys():
            print("    ",action,"->",rules[tag][action])


def process_data(pipelines,abac,teams):
    logging.info("Entering process_data")

    for pName in pipelines.keys():
        print(pName)
        ALL=False
        for tag in pipelines[pName]:
            if tag in abac.keys():
                printUsers(tag,abac,teams)
            else:
                if ALL == False and '*' in abac.keys():
                    printUsers("*",abac,teams)
                    ALL=True
                elif ALL == True:
                    logging.info("Already process ALL tags rule for this pipeline")
def printUsers(tag, abac, teams):
    logging.info("Entering printUsers: %s", tag)
    print ("  ", tag)
    for action in abac[tag].keys():
        teamId= abac[tag][action]
        print (f"    {action}: {teams[teamId]['users']}")


def get_permissions(teams):
    logging.info("Entering get_permissions")
    url = CF_URL + '/api/abac'
    resp=requests.get(url,
        headers = {"content-type":"application/json",
                   "Authorization": CF_API_KEY})
    if (resp.status_code != 200 and resp.status_code != 201):
        logging.error("API call to get permissions failed with code %s" % (resp.status_code))
        logging.error("Error: " + resp.text)
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

def get_pipelines(list):
    logging.info("Entering get_pipelines")
    url = CF_URL + '/api/pipelines/'

    pipelines={}
    for i in range(1,len(list)):
        pName=list[i]
        logging.info ("Processing pipeline %s", pName)
        P=urllib.parse.quote_plus(pName)
        resp=requests.get(url + P,
            headers = {"content-type":"application/json",
                       "Authorization": CF_API_KEY})
        if (resp.status_code != 200 and resp.status_code != 201):
            logging.error("API call to get pipeline %s failed with code %s", pipeline,resp.status_code)
            logging.error("Error: " + resp.text)
            sys.exit(resp.status_code)
        data=resp.json()
        if 'labels' in data['metadata']:
            tags=data['metadata']['labels']['tags']
        else:
            tags=['untagged']
        pipelines[pName]=tags
    return pipelines

def get_teams():
    logging.info("Entering get_teams")
    url = CF_URL + '/api/team'

    resp=requests.get(url,
        headers = {"content-type":"application/json",
                   "Authorization": CF_API_KEY})
    if (resp.status_code != 200 and resp.status_code != 201):
        logging.error("API call to get teams failed with code %s" % (resp.status_code))
        logging.error("Error: " + resp.text)
        sys.exit(resp.status_code)

    data=resp.json()
    teams={}
    for team in data:
        name = team['name']
        id   = team['_id']
        logging.info ("Processing team %s", name)
        teams[id]={}
        teams[id]['name']=name
        teams[id]['users']=[]
        for user in team['users']:
            teams[id]['users'].append(user['userName'])

    return teams

if __name__ == "__main__":
    main()
