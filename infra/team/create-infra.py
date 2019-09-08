#!/usr/bin/env python

import csv
import logging
import os
import subprocess
from queue import Queue
from threading import Thread
from time import time


logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

logger = logging.getLogger(__name__)

def create_project(team_name):
    command = ['./create-project.sh', 'ksw-{}'.format(team_name)]
    print(subprocess.check_output(command))

def create_infra(team_name, password):
    organization = os.environ.get('ORGANIZATION_ID')
    print(subprocess.check_output(['terraform', 'apply', 
        '-auto-approve',
        '-var', 'folder_id={}'.format(organization),
        '-var', 'team_name={}'.format(team_name),
        '-var', 'password={}'.format(password),
        '-state', 'ksw-{}.tfstate'.format(team_name),
        './lab']))

class TeamCreationWorker(Thread):

    def __init__(self, queue):
        Thread.__init__(self)
        self.queue = queue

    def run(self):
        while True:
            # Get the work from the queue and expand the tuple
            team_name, password = self.queue.get()
            try:
                print('team_name: {}'.format(team_name))
                create_project(team_name)
                create_infra(team_name, password)
                print('team_name: {}'.format('Environment created'))
            finally:
                self.queue.task_done()


def main():
    ts = time()
    # Create a queue to communicate with the worker threads
    queue = Queue()
    # Create 8 worker threads
    for x in range(8):
        worker = TeamCreationWorker(queue)
        # Setting daemon to True will let the main thread exit even though the workers are blocking
        worker.daemon = True
        worker.start()
    # Open team list
    teams_file = open('teams.csv')
    teams = csv.reader(teams_file, delimiter=';')
    # Put the tasks into the queue as a tuple
    for team in teams:
        logger.info('Queueing {}'.format(team))
        team_name = team[0]
        password = team[1]
        queue.put((team_name, password))
    # Causes the main thread to wait for the queue to finish processing all the tasks
    queue.join()
    logging.info('Took %s', time() - ts)

if __name__ == '__main__':
    main()
