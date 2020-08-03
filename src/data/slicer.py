from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import Normalizer
import nibabel as nib
# from nilearn import plotting
import re
import numpy as np
import pandas as pd
import os
from os import listdir, fsencode
import math
from PIL import Image
import sys
import os

data_dir = str(sys.argv[1])
interim_dir = str(sys.argv[2])

nii_files = [f for f in os.listdir(os.fsencode(data_dir))
             if not f.startswith(b'.')]

for nii_file in nii_files:
    f = os.fsencode(nii_file)
    f = f.decode('utf-8')
    nii_file = nib.load((data_dir + f))
    data = nii_file.get_fdata()
    data = data*(185.0/np.percentile(data, 97))
    scaler = StandardScaler()
    for img_slice in range(0, 80):
        clipped = data[:, :, (45+img_slice)]
        image_data = Image.fromarray(clipped).convert('RGB')
        image_data.save((interim_dir + f[:-7] + '-'+str(img_slice)+'.jpg'))
