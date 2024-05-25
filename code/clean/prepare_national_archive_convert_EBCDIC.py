# -*- coding: utf-8 -*-
'''
Function: This file converts EBCDIC raw files from National Archives to ASCII

Required Packages:
For Python 3, we need to install the following packages:
- codecs (as of Apr-27-2024)

This can be run as a subprocess in STATA using the following command:
python script prepare_national_archives_convert_EBCDIC.py
'''

import codecs
import os
# Directory where the data are stored
input_path = "../../input/soi/national_archive"
output_path = "../../output/soi/national_archive_converted"



# open 1965, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y65_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 1868  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y65_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()


# open 1966, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y66_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 1978  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y66_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()



# open 1967, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y67_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 1978  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y67_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()



# open 1968, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y68_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 1978  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y68_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()



# open 1969, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y69_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 2088  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y69_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()



# open 1970, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y70_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 2198  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y70_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()





# open 1976, EBCDIC format
with open(f"{input_path}/RG058.CORP.Y76_EBCDIC.txt", "rb") as ebcdic:
    ascii_txt = codecs.decode(ebcdic.read(), "cp500")

chunks = len(ascii_txt)
chunk_size = 1197  # One observation length
data_lst = [ascii_txt[i:i+chunk_size] for i in range(0, chunks, chunk_size)] # split to different observations. 
f = open(f"{output_path}/RG058.CORP.Y76_ASCII.txt", "w")
for str_line in data_lst:
    f.write(f"{str_line}\n")
f.close()

