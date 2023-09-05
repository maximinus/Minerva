import os
import shutil

from pathlib import Path

from minerva.logs import logger

# code to create / delete files etc..
FILE_DEBUG = True


def rename_path(filepath, new_name):
    logger.info(f'Renaming file {filepath} to {new_name}')
    if FILE_DEBUG:
        return
    new_path = filepath.parent / new_name
    try:
        os.rename(filepath, new_path)
        return True
    except OSError as ex:
        logger.error(f'Could not rename {filepath} to {new_path}')
    return False


def delete_file(filepath):
    logger.info(f'Deleting file {filepath}')
    if FILE_DEBUG:
        return
    # if it doesn't exist, we don't need to do anything
    if os.path.exists(filepath):
        logger.error(f'Asked to delete an non-existent file: {filepath}')
        return True
    try:
        os.remove(filepath)
        return True
    except OSError:
        return False


def delete_directory(filepath):
    logger.info(f'Deleting directory {filepath}')
    if FILE_DEBUG:
        return
    # if it doesn't exist, we don't need to do anything
    if os.path.exists(filepath):
        logger.error(f'Asked to delete an non-existent file: {filepath}')
        return True
    try:
        shutil.rmtree(filepath)
        return True
    except OSError as ex:
        logger.error(f'Failed to delete {filepath}: {ex}')
    return False


def create_file(filepath):
    logger.info(f'Creating file {filepath}')
    if FILE_DEBUG:
        return
    # the file will be empty
    try:
        Path(filepath).touch()
        return True
    except FileExistsError:
        return True
    except OSError as ex:
        logger.error(f'Failed to delete {filepath}: {ex}')
    return False


def create_directory(filepath):
    logger.info(f'Creating directory {filepath}')
    if FILE_DEBUG:
        return
    # the directory will be empty
    if os.path.exists(filepath):
        logger.error(f'Asked to create a directory that already exists: {filepath}')
        return True
    try:
        os.makedirs(filepath)
        return True
    except OSError:
        return False

