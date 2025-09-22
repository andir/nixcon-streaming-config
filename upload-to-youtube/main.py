#!/usr/bin/python

import random
import time

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
    

def retrieve_pretalx_data(url):
    response = requests.get(url)
    j = response.json()
    return Schedule(conference_title=j['schedule']['conference']['title'], raw=j)
   

@dataclass
class Recording:
   filename: str
   path: pathlib.Path
   session_id: int


def get_recordings(path: pathlib.Path) -> Recording:
    for file in path.glob('*.mkv'):
        fn = file.parts[-1]
        try:
            session_id_s, _ = fn.split('_', 1)
        except ValueError:
            continue

        session_id = int(session_id_s)

        yield Recording(filename=fn, path=file.absolute(), session_id=session_id)


def get_intro_file(intros_path: pathlib.Path, session):
    f = list(intros_path.glob(f'{session["id"]}_*.mkv'))
    return f[0]

@contextmanager
def extract_thumbnail(video_path: pathlib.Path):
    with tempfile.NamedTemporaryFile(suffix=".jpg") as fh:
       command = ["ffmpeg", "-y", "-i", str(video_path), "-vframes", "1", "-q:v", "2", fh.name]
       print(f'running: {" ".join(command)}')
       subprocess.call(" ".join(command), universal_newlines=True, shell=True)
       yield fh.name

       
CLIENT_SECRETS_FILE = "client_secrets.json"
SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]

def get_authenticated_yt_service():
    flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
    credentials = flow.run_local_server()
    return build("youtube", "v3", credentials=credentials)


def upload_video(yt, title: str, description: str, video_file: pathlib.Path, thumbnail_file: pathlib.Path, tags=None, sponsored=False):
    if tags is None:
        tags = []

    request_body = dict(
        snippet=dict(
            title=title,
            description=description,
            tags=tags,
            cateogryId=28,
        ),
        status=dict(privacyStatus="unlisted", license="creativeCommon", selfDeclaredMadeForKids=False),
        paidProductPlacementDetails=dict(
            hasPaidProductPlacement=sponsored,
        )
    )

    insert_request = yt.videos().insert(
        part=",".join(request_body.keys()),
        body=request_body,
        media_body=MediaFileUpload(video_file, chunksize=-1, resumable=True))

    return resumable_upload(insert_request)


# copied from the amazing (outdated!?!) Python2 examples in the Google YT API Docs.
RETRIABLE_STATUS_CODES = [500, 502, 503, 504]
RETRIABLE_EXCEPTIONS = (httplib2.HttpLib2Error, IOError)
def resumable_upload(insert_request):
  response = None
  error = None
  retry = 0
  while response is None:
    try:
      print("Uploading file...")
      status, response = insert_request.next_chunk()
      if response is not None:
        if 'id' in response:
          print(f"Video id '{response['id']}' was successfully uploaded.", )
          return response['id']
        else:
          print(f"The upload failed with an unexpected response: {response}")
          return None
    except HttpError as e:
      if e.resp.status in RETRIABLE_STATUS_CODES:
        error = "A retriable HTTP error %d occurred:\n%s" % (e.resp.status,
                                                             e.content)
      else:
        raise
    except RETRIABLE_EXCEPTIONS as e:
      error = "A retriable error occurred: %s" % e

    if error is not None:
      print(error)
      retry += 1
      if retry > MAX_RETRIES:
        print("No longer attempting to retry.")
        return None

      max_sleep = 2 ** retry
      sleep_seconds = random.random() * max_sleep
      print(f"Sleeping {sleep_seconds} seconds and then retrying...")
      time.sleep(sleep_seconds)


def does_video_exist(yt, title) -> bool:
    req = yt.search().list(part="snippet", forMine=True, type="video", q=title, maxResults=1)
    response = req.execute()
    print(response['items'])
    return any( item['snippet']['title'] == title for item in response['items'] )
      
def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--folder', required=True, help="The folder containing the video files you want to upload. Files should be in the format <Pretalx_ID>_….mkv.")
  parser.add_argument("--pretalx-json", required=True, help="URL to the pretalx JSON for the conference")
  parser.add_argument("--privacy-status", choices=VALID_PRIVACY_STATUSES,
    default=VALID_PRIVACY_STATUSES[2], help="Video privacy status.")
  parser.add_argument('--intros-path', required=True, help="The folder containing the intros. Same naming structured required as for the actual recordings.")
  parser.add_argument('--sponsored', default=False,  action=argparse.BooleanOptionalAction)

  # parser.add_argument('--playlist-id', default=None, help="The ID of the playlist to add videos to.")
  # parser.add_argument('--playlist-title', default=None, help="The Title of the playlist. By default populated from the pretalx inpu.")

  args = parser.parse_args()

  schedule = retrieve_pretalx_data(args.pretalx_json)
  talks = schedule.talks()

  recordings = []
  
  for recording in get_recordings(pathlib.Path(args.folder)):
      session = talks.get(recording.session_id)
      if not session:
          print(f'Missing session for recording {recording} in pretalx?!')
      else:
          print(f'Found session for recording {recording.filename}: {session["title"]}')
          recordings += [(recording, session)]

  if not recordings:
      print('No recordings or no matching session data found')
      return

  yt = get_authenticated_yt_service()

  for (recording, session) in recordings:
      intro_path = get_intro_file(pathlib.Path(args.intros_path), session)
      if not intro_path.exists():
          print(f"Missing intro for {recording}")
          return

      title = f"NixCon 2025 - {session['title']}"

      # this session is one character over the limit, lets drop the dash
      if session['id'] == 73840 or len(title) > 100:
          title = f"NixCon 2025 ${session['title']}"
          
      d = session.get('description', "")
      description = f"{d}\n\n---------------------\n\n{session['url']}\n\n5-7 September 2025\nOST Rapperswill\nSwitzerland\nhttps://2025.nixcon.org\n\n\nRecording with support from Chaos West TV & C3VOC\n\n---------------------\n\nMusic by tonstr.studio\nhttps://tonstrstudio.bandcamp.com/album/lava\n\n---------------------\n\nRelease under CC-BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)\n\n"

      # searching doesn't work, says not permitted.. I don't care much anymore. This API is insane.
      #if does_video_exist(yt, title):
      #    print(f'Title {title} already exists, skipping')

      with extract_thumbnail(intro_path) as thumbnail_fn:
          print(thumbnail_fn)

          print(f"Uploading: {title}") 
          video_id = upload_video(yt, title, description, str(recording.path.absolute()), thumbnail_fn)
          print("Uploading thumbnail")
          r = yt.thumbnails().set(videoId=video_id, media_body=MediaFileUpload(thumbnail_fn))
          print(r.execute())
          

if __name__ == '__main__':
  main()
