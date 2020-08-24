from keras.preprocessing.image import ImageDataGenerator
from keras.models import load_model

import numpy as np
import pandas as pd
import itertools

import sys

test_dir = str(sys.argv[1])
subjects_file = str(sys.argv[2])
model = load_model(sys.argv[3])
out_file = str(sys.argv[4])

# print(model.summary())

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
sex_test = []
slice_test = []
deplist = []
test_generator.reset()

IDSet = [line.rstrip('\n') for line in open(subjects_file)]
# IDset = set(prediction_data['ID'].values)
# IDset = list(IDset)

# IDlist = []
IDlist = list(
            itertools.chain.from_iterable(
                itertools.repeat(x, batch_size)
                for x in IDSet))
# for filename in test_generator.filenames:
#    IDlist.append(filename.split('-')[0])
#    IDlist.append(filename.split('_')[1][0])

test_generator.reset()
predicty = model.predict(
    x=test_generator,
    verbose=0,
    steps=test_generator.n/batch_size)

prediction_data = pd.DataFrame()
prediction_data['ID'] = IDlist
prediction_data['Prediction'] = predicty


final_prediction = []
final_labels = []
final_site = []

for x in IDSet:
    check_predictions = prediction_data[prediction_data['ID'] == x][
        'Prediction']
    predicty = check_predictions.reset_index(drop=True)
    final_prediction.append(np.median(predicty))

predicty1 = final_prediction

out_data = pd.DataFrame()
out_data['ID'] = IDSet
out_data['Pred_Age'] = predicty1
out_data.sort_values(by=['ID'])
out_data.to_csv(out_file, index=False)
