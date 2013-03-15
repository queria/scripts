#!/usr/bin/env python

import os
import sys
import re
import traceback
from pprint import pprint as pp

_debug = True

class SongError(ValueError):
    pass
class AlbumError(ValueError):
    pass
class ArtistError(ValueError):
    pass

def safe(text):
    text = re.sub('[^a-zA-Z0-9-]+','_', text)
    if text.endswith('_'):
        text = text[:-1]
    if text.startswith('_'):
        text = text[1:]
    return text

def print_ren(mark, desc, src, dst):
    print('[REN{0}] Renaming {1}:\n =  {2}\n => {3}'.format(
        mark, desc, src, dst))

def print_skip(msg):
    print('[SKIP] {0}'.format(msg))

def rename_artist(artist):
    orig_path = os.path.realpath(artist)
    prefix = os.path.dirname(orig_path)
    artist = os.path.basename(orig_path)
    new_artist = safe(os.path.basename(orig_path))

    prefix = os.path.relpath(prefix)

    orig_path = os.path.join(prefix, artist)
    new_path = os.path.join(prefix, new_artist)

    if orig_path == new_path:
        print_ren('-', 'already done', orig_path, '-\'\'-')
    else:
        print_ren('A', 'artist', orig_path, new_path)

        os.rename(orig_path, new_path)

    return (prefix, new_artist)

def split_artist_album(prefix, artist_album):
    m = re.match(
        '^(.*)_-_(.*)_-_[a-z0-9]+_---_Jamendo_-_.*',
        artist_album)
    if not m:
        raise ArtistError(artist_album+' XXX')
    artist = m.group(1)
    new_dir = os.path.join(prefix, artist)
    if not os.path.isdir(new_dir):
        os.mkdir(new_dir)
    os.rename(
        os.path.join(prefix, artist_album),
        os.path.join(new_dir, artist_album.replace('_',' ')))
    return artist

def rename_album(prefix, artist, album):
    # Album directory name pattern:
        # "{artist} - {album} - {id} --- Jamendo - {format}
    # and we want to obtain just '{album}'
    if safe(album) == album:
        print_ren('-', 'already done',
                  os.path.join(prefix, artist, album),
                  '')
        return album
    orig_path = os.path.join(prefix, artist, album)
    m = re.match(
        '^(.*) - (.*) - [a-zA-Z0-9]+ --- Jamendo - .*$',
        album)
    if m:
        album = safe(m.group(2))
        new_path = os.path.join(prefix, artist, album)
        print_ren('B', 'album', orig_path, new_path)
        os.rename(orig_path, new_path)
        return album
    else:
        raise AlbumError('Invalid album name {0}'.format(
            os.path.join(prefix, artist, album)))

def rename_song(prefix, artist, album, song):
    # song filename pattern:
        # {song_number} - {Artist} - {SongName}.mp3
    m = re.match(
        '^([0-9]{2}) - (.*) - (.*)\.(.{1,5})', song)
    if m:
        new_song = '{0}_-_{1}'.format(
            m.group(1), m.group(3))
        new_song = safe(new_song)
        new_song = '{0}.{1}'.format(new_song, m.group(4))
        orig_path = os.path.join(prefix, artist, album, song)
        new_path = os.path.join(prefix, artist, album, new_song)
        if os.path.exists(new_path):
            raise SongError('Target song file already exists: {0}'.format(
                new_path))
        print_ren('S', 'song', orig_path, new_path)
        os.rename(orig_path, new_path)
    else:
        print_skip("Invalid or already processed song filename: {0}".format(song))

def process_album(prefix, artist, album):
    album = rename_album(prefix, artist, album)
    for song in os.listdir( os.path.join(prefix, artist, album) ):
        rename_song(prefix, artist, album, song)

def process_artist(artist):
    prefix, artist = rename_artist(artist)
    has_albums = False
    for album in os.listdir(artist):
        if not os.path.isdir(os.path.join(prefix, artist, album)):
            continue
        try:
            process_album(prefix, artist, album)
            has_albums = True
        except (AlbumError,OSError), err:
            if _debug:
                print_skip('Unable to process album {0}'.format(
                    os.path.join(artist, album)))
                print(" @{0} {1}".format(
                    traceback.extract_tb(sys.exc_traceback)[-1][1],
                    err.args))
                #traceback.print_exc(err)
    if not has_albums:
        process_artist(
            os.path.join(
                prefix, split_artist_album(prefix, artist)))


if __name__ == '__main__':
    help_req = ( '-h' in sys.argv or '--help' in sys.argv)
    if not help_req and len(sys.argv) > 1:
        for artist in sys.argv[1:]:
            try:
                process_artist(artist)
            except ArtistError, e:
                print_skip(str(e))
    else:
        print('Specify absolute or relative path to artist folders,\n'
              ' which contains unpacked jamendo albums.')
        print('\nFor example:')
        print(' {0} ./Jackson ./Maddona ~/music/Mad\\ Mav'.format(
            sys.argv[0]))
