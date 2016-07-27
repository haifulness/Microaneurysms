import xlrd
from sklearn import svm


################################################################################
# Read xlsx file
#
def open_xlsx(path):
	data = []
	label = []

	# Open the file
	book = xlrd.open_workbook(path)

	# Get the first worksheet
	sheet = book.sheet_by_index(0)

    # read a cell
	#cell = first_sheet.cell(1, 2)

	# Read number of entries
	# Positive samples
	sample_pos = int(sheet.cell(1, 25).value)
	# Negative samples
	sample_neg = int(sheet.cell(0, 25).value)

	# Start scanning the worksheet to read data
	for index in range(0, sample_neg):
		print(index)
		
		label.append(float(sheet.cell(index + 1, 1).value))

		data.append([])
		# Max Intensity
		data[len(data)-1].append(float(sheet.cell(index + 1, 4).value))
		# Frequency of Max Intensity
		data[len(data)-1].append(float(sheet.cell(index + 1, 5).value))
		# Avg Intensity
		data[len(data)-1].append(float(sheet.cell(index + 1, 6).value))
		# L1-norm
		data[len(data)-1].append(float(sheet.cell(index + 1, 7).value))
		# L2-norm
		data[len(data)-1].append(float(sheet.cell(index + 1, 8).value))
		# Standard Deviation
		data[len(data)-1].append(float(sheet.cell(index + 1, 9).value))
		# Mean Absolute Deviation
		data[len(data)-1].append(float(sheet.cell(index + 1, 10).value))

		if index < sample_pos:
			label.append(float(sheet.cell(index + 1, 12).value))

			data.append([])
			# Max Intensity
			data[len(data)-1].append(float(sheet.cell(index + 1, 15).value))
			# Frequency of Max Intensity
			data[len(data)-1].append(float(sheet.cell(index + 1, 16).value))
			# Avg Intensity
			data[len(data)-1].append(float(sheet.cell(index + 1, 17).value))
			# L1-norm
			data[len(data)-1].append(float(sheet.cell(index + 1, 18).value))
			# L2-norm
			data[len(data)-1].append(float(sheet.cell(index + 1, 19).value))
			# Standard Deviation
			data[len(data)-1].append(float(sheet.cell(index + 1, 20).value))
			# Mean Absolute Deviation
			data[len(data)-1].append(float(sheet.cell(index + 1, 21).value))

	return data, label


################################################################################
# Main
#
data, label = open_xlsx("result_HE.xlsx")
#print(len(data), len(data[0]))

#indices = random.

'''
train_data = data[:(len(data)*39/40)]
train_label = label[:(len(data)*39/40)]

test_data = data[(len(data)*39/40):]
test_label = label[(len(data)*39/40):]

clf = svm.SVC()
clf.fit(train_data, train_label)
prediction = clf.predict(test_data)

tp, np, tf, nf = 0, 0, 0, 0

for i in range(0, len(prediction)):
	print(prediction[i], test_label[i])
'''

file_w = open("result_HE.txt", "w")

for i in range(0, len(label)):
	file_w.write(str(data[i][0]))
	file_w.write(",")
	file_w.write(str(data[i][1]))
	file_w.write(",")
	file_w.write(str(data[i][2]))
	file_w.write(",")
	file_w.write(str(data[i][3]))
	file_w.write(",")
	file_w.write(str(data[i][4]))
	file_w.write(",")
	file_w.write(str(data[i][5]))
	file_w.write(",")
	file_w.write(str(data[i][6]))
	file_w.write(",")
	file_w.write(str(label[i]))
	file_w.write("\n")

file_w.close()