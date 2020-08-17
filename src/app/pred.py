import keras
from keras.applications.resnet50 import ResNet50
from keras.preprocessing import image
from keras import models, optimizers
from keras.preprocessing.image import ImageDataGenerator
from keras import regularizers
from keras.layers import Conv2D, MaxPooling2D, Flatten, Dense
from keras import models
from keras import layers
from keras import optimizers

import numpy as np
import pandas as pd
import math

#import h5py
from keras.models import load_model
import sys
import os
from os import listdir

test_dir = str(sys.argv[1])
model = load_model(sys.argv[2])
out_file = str(sys.argv[3])

#print(model.summary())

batch_size = 80

datagen_test = ImageDataGenerator(
    rescale=1./255,
    horizontal_flip=False,
    vertical_flip=False,
    featurewise_center=False,
    featurewise_std_normalization=False)

test_generator = datagen_test.flow_from_directory(
        directory=test_dir,
        batch_size=batch_size,
        seed=42,
        shuffle=False,
        class_mode=None)

labels_test = []
sitelist = []
IDlist = []
sex_test = []
slice_test = []
deplist = []
test_generator.reset()

for filename in test_generator.filenames:
    IDlist.append(filename.split('-')[0])
    #IDlist.append(filename.split('_')[1][0])

test_generator.reset()
predicty = model.predict(
    x=test_generator,
    verbose=0,
    steps=test_generator.n/batch_size)

prediction_data = pd.DataFrame()
prediction_data['ID'] = IDlist
prediction_data['Prediction'] = predicty

IDset = set(prediction_data['ID'].values)
IDset = list(IDset)

final_prediction = []
final_labels = []
final_site = []

for x in IDset:
    check_predictions = prediction_data[prediction_data['ID'] == x][
        'Prediction']
    predicty = check_predictions.reset_index(drop=True)
    final_prediction.append(np.median(predicty))

predicty1 = final_prediction

out_data = pd.DataFrame()
out_data['ID'] = IDset
out_data['Pred_Age'] = predicty1
out_data.to_csv(out_file, index=False)
