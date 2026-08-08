#!/usr/bin/python
import re
import random
import time

import json
import httplib2
import argparse
import requests
from dataclasses import dataclass
from functools import cache
import pathlib
import tempfile
import subprocess
from contextlib import contextmanager
from googleapiclient.http import MediaFileUpload
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.http import MediaFileUpload



VALID_PRIVACY_STATUSES = ("public", "private", "unlisted")


@dataclass
class Schedule:
    conference_title: str
    raw: dict

    def talks(self) -> dict:
        """
          Dict of all the talks with their ID as key.
        """
        c = self.raw['schedule']['conference']

        sessions = {}
        for day in c['days']:
            for (_, room) in day['rooms'].items():
                for session in room:
                    sessions[session['id']] = session

        return sessions


    def get_talk_for_url(self, url):
        for _, talk in self.talks().items():
            if talk['url'] == url:
                return talk
    

def extract_talk_url(text):
    e = re.compile(r'^https://talks.nixcon.org/nixcon-2025/talk/[A-Z0-9]{6}/$')
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("https://talks.nixcon.org/nixcon-2025/talk/"):
            return line
        if m := e.match(text):
            return line
 

def retrieve_pretalx_data(url):
    response = requests.get(url)
    j = response.json()
    return Schedule(conference_title=j['schedule']['conference']['title'], raw=j)
   

@dataclass
class Recording:
   filename: str
   path: pathlib.Path
   session_id: int


CLIENT_SECRETS_FILE = "client_secrets.json"
SCOPES = ["https://www.googleapis.com/auth/youtube"]

def get_authenticated_yt_service():
    flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
    
    credentials = flow.run_local_server(port=random.randint(8082, 8095))
    return build("youtube", "v3", credentials=credentials)


def get_description(session) -> str:
      d = session.get('description', "")
      description = f"{d}\n\n---------------------\n\n{session['url']}\n\n5-7 September 2025\nOST Rapperswill\nSwitzerland\nhttps://2025.nixcon.org\n\n\nRecording with support from Chaos West TV & C3VOC\n\n---------------------\n\nMusic by tonstr.studio\nhttps://tonstrstudio.bandcamp.com/album/lava\n\n---------------------\n\nRelease under CC-BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)\n\n"


      parts = [d]
      
      if session['persons']:
          speakers = ", ".join(p['name'] for p in session['persons'])
          parts += [ f"Speaker(s): {speakers}"]

      parts += [f"{session['url']}"]
      parts += [f"5-7 September 2025\nOST Rapperswill\nSwitzerland\nhttps://2025.nixcon.org\n\n\nRecording with support from Chaos West TV & C3VOC\nRecording License: CC-BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)"]
      parts += ["Music by tonstr.studio\nhttps://tonstrstudio.bandcamp.com/album/lava\nMusic License: CC-BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)"]
      parts += []

      description = "\n\n---------------------\n\n".join(parts)

      return description


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--pretalx-json", required=True, help="URL to the pretalx JSON for the conference")
  parser.add_argument("--playlist-id", required=True, help="The ID of your playlist")
  args = parser.parse_args()

  schedule = retrieve_pretalx_data(args.pretalx_json)
  talks = schedule.talks()

  yt = get_authenticated_yt_service()



  next_page_token = None

  while True:
    request = yt.playlistItems().list(
        part="snippet",
        playlistId=args.playlist_id,
        maxResults=50,
        pageToken=next_page_token
    )
    response = request.execute()

    for item in response['items']:
        title = item['snippet']['title']
        video_id = item['snippet']['resourceId']['videoId']
        description = item['snippet']['description']

        print(f"Processing {title}")
        talk_url = extract_talk_url(description)
        print(f"talk_url: {talk_url}")
        if talk_url is None:
            return
        session = schedule.get_talk_for_url(talk_url)
        print(f"Session: {session}")
        if not session:
            break
        new_description = get_description(session)
        if new_description == description:
            print("Description the same. Skipping.")
        else:
            print("Updating description.")
            print("Old value:", json.dumps(item['snippet']))
            new_snippet = item['snippet'].copy()
            new_snippet['description'] = new_description
            new_snippet['categoryId'] = 28
            print("new value:", json.dumps(new_snippet))

            req = yt.videos().update(part="snippet", body=dict(
                id=video_id,
                snippet=new_snippet,
            ))
            print(req.execute())

    next_page_token = response.get('nextPageToken')
    if not next_page_token:
        break
  #description = get_description(session) 

          

if __name__ == '__main__':
  main()
