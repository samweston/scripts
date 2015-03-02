#!/usr/bin/python

# Requires oauth2client and google-api-python-client.
# Install with:
# pip install oauth2client
# pip install google-api-python-client

# Documentation at https://developers.google.com/google-apps/calendar/v3/reference/events/insert

# Input file calendar_batch_insert.csv with columns:
# email
# summary
# description
# time_zone (TZ* format, e.g. Pacific/Auckand)
# start_time (RFC 3339, i.e. yyyy-mm-ddTHH:MM:SS)
# finish_time (RFC 3339, i.e. yyyy-mm-ddTHH:MM:SS)

import sys
import csv

from apiclient import sample_tools
from oauth2client import client

def main(argv):
  service, flags = sample_tools.init(
      argv, 'calendar', 'v3', __doc__, __file__,
      scope='https://www.googleapis.com/auth/calendar')

  try:
    with open('calendar_batch_insert.csv') as csvfile:
      reader = csv.DictReader(csvfile)
      for row in reader:
        event = {
          'email': row['email'],
          'summary': row['summary'],
          'description': row['description'],
          'start': {
            'dateTime': row['start_time'],
            'timeZone': row['time_zone']
          },
          'end': {
            'dateTime': row['finish_time'],
            'timeZone': row['time_zone']
          },
          'reminders': {
            'useDefault': False,
            'overrides': [
              {
                'method': 'email',
                'minutes': 30
              },
              {
                'method': 'popup',
                'minutes': 30
              }
            ]
          },
          'transparency': 'transparent'
        }

        imported_event = service.events().insert(calendarId='primary',
            body=event).execute()

  except client.AccessTokenRefreshError:
    print ('The credentials have been revoked or expired, please re-run the '
           'application to re-authorize')

if __name__ == '__main__':
  main(sys.argv)
