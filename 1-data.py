################################################################################
#
# Author: Hai Tran
# Date: June 26, 2016
#
from __future__ import print_function
import xml as xml
import xml.dom.minidom as minidom
import cv2
import numpy
from numpy import linalg as LA
from matplotlib import pyplot as plt
import random
import xlsxwriter


################################################################################
#
# Constants
#
DATAPATH = "ddb1_v02_01/"
NUM_IMG = 89
IMG_WIDTH = 1500
IMG_HEIGHT = 1152
NUM_PATCHES_PER_IMG = 200
PATCH_SIZE = 10

NUM_IMG_TEST = 25

################################################################################
#
# Load Image
#
def loadImage(img_num):
	if img_num < 10:
		imgpath = DATAPATH + "images/diaretdb1_image00" + str(img_num) + ".png"
	else:
		imgpath = DATAPATH + "images/diaretdb1_image0" + str(img_num) + ".png"

	img = cv2.imread(imgpath, 1)
	return img
		

################################################################################
#
# Load representative points from a XML file
#
def loadXML(img_num):
	# All coordinators are stored here
	point_list = []
	# Read through all four XML files
	for xml_num in range(0, 4):
		# Generate path to xml file
		if img_num < 10:
			xmlpath = DATAPATH + "groundtruth/diaretdb1_image00" + \
						str(img_num) + "_0" + str(xml_num+1) + "_plain.xml"
		else:
			xmlpath = DATAPATH + "groundtruth/diaretdb1_image0" + \
						str(img_num) + "_0" + str(xml_num+1) + "_plain.xml"

		# Load all lines in the file
		lines = [line.rstrip('\n') for line in open(xmlpath)]
		# Scan through each line
		for line in lines:
			# Skip introductory lines
			if line[0:9] == "<marking>":
				# Parse XML
				xml_line = minidom.parseString(line)

				# Only process red small dots
				markingtype = xml_line.getElementsByTagName("markingtype")
				if getText(markingtype[0].childNodes) == "Red_small_dots":
					rep_point = xml_line.getElementsByTagName("representativepoint")
					# Read the child node
					coords2d = rep_point[0].getElementsByTagName("coords2d")
					
					# Split into coord_x and coord_y
					point = getText(coords2d[0].childNodes).split(",")
					
					# Convert from string to integer
					point[0] = int(point[0])
					point[1] = int(point[1])
					
					# Add to list
					point_list.append([])
					point_list[len(point_list)-1].append(point[0])
					point_list[len(point_list)-1].append(point[1])

	#print(len(point_list))
	return point_list


################################################################################
#
# Get text from a XML node
# Source: https://docs.python.org/3/library/xml.dom.minidom.html
#
def getText(nodelist):
    rc = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
    return ''.join(rc)


################################################################################
#
# Load all representative points of all images
#
def loadAllRepPoints():
	sys.stdout.write("Loading XML files...")
	
	# Create a list for 89 images
	coord_list = [None] * NUM_IMG

	# Load data from individual image
	for i in range (0, NUM_IMG):
		coord_list[i] = loadXML(i+1)

	sys.stdout.write(" done\n")

	return coord_list


################################################################################
#
# Generate patches
#
def generatePatches(img_num, patch_size):
	point_list = loadXML(img_num)

	# Store all patches
	coord_list = []
	label_list = []

	# If the number of representative points are too small, it takes forever
	# to random positive samples. Therefore, I set a lower bar here. In 
	# particular, image #46 has only one representative point.
	if len(point_list) > 4:

		# Number of positive and negative samples.
		# We expect to have three times more of negative samples than positive ones.
		count_pos = 0
		count_neg = 0

		while len(coord_list) < NUM_PATCHES_PER_IMG:
			coord_x = random.randint(0, IMG_HEIGHT - patch_size)
			coord_y = random.randint(0, IMG_WIDTH - patch_size)

			isPositive = isPositiveSample(coord_x, coord_y, patch_size, 
				point_list)

			# Positive sample
			if isPositive and (count_pos < NUM_PATCHES_PER_IMG / 4):
				coord_list.append([])
				coord_list[len(coord_list)-1].append(coord_x)
				coord_list[len(coord_list)-1].append(coord_y)
				label_list.append(1)
				count_pos += 1

			# Negative sample
			elif (not isPositive) and (count_neg < NUM_PATCHES_PER_IMG * 3/4):
				coord_list.append([])
				coord_list[len(coord_list)-1].append(coord_x)
				coord_list[len(coord_list)-1].append(coord_y)
				label_list.append(0)
				count_neg += 1

			#print(count_pos, count_neg)

	return coord_list, label_list


################################################################################
#
# Check if a patch contains a representative point (positive sample)
#
def isPositiveSample(coord_x, coord_y, patch_size, point_list):
	found = False

	for point in point_list:
		if (coord_x < point[0] < coord_x + patch_size) \
		and (coord_y < point[1] < coord_y + patch_size):
			found = True
			break

	return found


################################################################################
#
# Load patch from image
#
def loadPatch(img_num, coord_x, coord_y, patch_size):
	img = loadImage(img_num)
	return img[coord_x : coord_x + patch_size, coord_y : coord_y + patch_size]


################################################################################
#
# Flatten a patch from a 2-dimension list to a 1-dimension one.
#
def patchFlatten(patch, patch_size):
	patch_flatten = [None] * (patch_size * patch_size)
	
	for i in range(0, patch_size):
		for j in range(0, patch_size):
			patch_flatten[i * patch_size + j] = patch[i][j][1]

	return patch_flatten


################################################################################
#
# Histogram Equalization
#
def histogramEqualization(patch):
	img_equalized = patch
	counter = [0] * 256
	sum_counter = [0] * 256

	# Count color frequency
	for value in range(0, 255):
		counter[value] = patch.count(value)

	# Normalized sum
	for value in range(1, 255):
		sum_counter[value] = sum(counter[:value])

	# Transform
	coeff = (float)(max(patch)) / (float)(len(patch))
	for i in range(0, len(patch)):
		img_equalized[i] = int(round((float)(sum_counter[patch[i]]) * coeff))

	return img_equalized


################################################################################
#
# Test
#
patches = {}

workbook = xlsxwriter.Workbook('result_HE.xlsx')
worksheet = workbook.add_worksheet()

worksheet.write(0, 0, "Image no.")
worksheet.write(0, 1, "Positive?")
worksheet.write(0, 2, "Coord-x")
worksheet.write(0, 3, "Coord-y")
worksheet.write(0, 4, "Max. Intensity")
worksheet.write(0, 5, "Freq of Max Intensity")
worksheet.write(0, 6, "Avg of Intensity")
worksheet.write(0, 7, "L1-norm")
worksheet.write(0, 8, "L2-norm")
worksheet.write(0, 9, "Standard Deviation")
worksheet.write(0, 10, "Mean Absolute Deviation")

worksheet.write(0, 11, "Image no.")
worksheet.write(0, 12, "Positive?")
worksheet.write(0, 13, "Coord-x")
worksheet.write(0, 14, "Coord-y")
worksheet.write(0, 15, "Max. Intensity")
worksheet.write(0, 16, "Freq of Max Intensity")
worksheet.write(0, 17, "Avg of Intensity")
worksheet.write(0, 18, "L1-norm")
worksheet.write(0, 19, "L2-norm")
worksheet.write(0, 20, "Standard Deviation")
worksheet.write(0, 21, "Mean Absolute Deviation")

for i in range(0, NUM_IMG):
	print("Loading data for image #", (i+1), '... ', end="")
	patches[i] = []
	coord_list, label_list = generatePatches(i+1, PATCH_SIZE)

	if len(coord_list) == NUM_PATCHES_PER_IMG:
		for j in range(0, len(coord_list)):
			img = loadPatch(i+1, coord_list[j][0], coord_list[j][1], PATCH_SIZE)
			img_flattened = patchFlatten(img, PATCH_SIZE)
			img_flattened = histogramEqualization(img_flattened)

			# Calculate maxima to get the maximal frequency
			maxima = max(img_flattened)

			# Convert to numpy so we can apply L1- and L2-norms
			a = numpy.asarray(img_flattened)

			if label_list[j] == 0:
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 0, i+1)
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 1, label_list[j])
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 2, coord_list[j][0])
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 3, coord_list[j][1])
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 4, maxima)
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 5, img_flattened.count(maxima))
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 6, sum(img_flattened)/len(img_flattened))
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 7, LA.norm(a, 1))
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 8, LA.norm(a, 2))
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 9, numpy.std(a))
				worksheet.write(i*NUM_PATCHES_PER_IMG*3/4 + j + 1, 10, numpy.mean(numpy.absolute(a - numpy.mean(a))))

			else:
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 11, i+1)
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 12, label_list[j])
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 13, coord_list[j][0])
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 14, coord_list[j][1])
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 15, maxima)
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 16, img_flattened.count(maxima))
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 17, sum(img_flattened)/len(img_flattened))
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 18, LA.norm(a, 1))
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 19, LA.norm(a, 2))
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 20, numpy.std(a))
				worksheet.write(i*NUM_PATCHES_PER_IMG/4 + j + 1 - NUM_PATCHES_PER_IMG*3/4, 21, numpy.mean(numpy.absolute(a - numpy.mean(a))))

	print("done")


# Create new chart objects.
print("Generating chart... ", end="")


# Chart 1: Freq of Maximal Intensity vs. L1 Norm
chart1 = workbook.add_chart({
	"type": "scatter"
})
chart1.set_title({
    "name": "Freq of Maximal Intensity vs. L1 Norm"
})
chart1.set_x_axis({
	"name": "Frequency of Maximal Intensity",
	"min": 0, 
	"max": 10,
	"major_unit": 2
})
chart1.set_y_axis({
	"name": "L1-norm",
	"max": 15000
})
# Add a series to the chart.
chart1.add_series({
	"name": "Non-MA",
	"categories": ["Sheet1", 1, 5, 10*NUM_PATCHES_PER_IMG*3/4+1, 5],
	"values": ["Sheet1", 1, 7, 10*NUM_PATCHES_PER_IMG*3/4+1, 7]
})
chart1.add_series({
	"name": "MA",
	"categories": ["Sheet1", 1, 15, 10*NUM_PATCHES_PER_IMG/4+1, 15],
	"values": ["Sheet1", 1, 17, 10*NUM_PATCHES_PER_IMG/4+1, 17]
})
# Insert the chart into the worksheet.
worksheet.insert_chart("C1", chart1)


# Chart 2: Freq of Maximal Intensity vs. L2 Norm
chart2 = workbook.add_chart({
	"type": "scatter"
})
chart2.set_title({
    "name": "Freq of Maximal Intensity vs. L2 Norm"
})
chart2.set_x_axis({
	"name": "Frequency of Maximal Intensity",
	"min": 0, 
	"max": 10,
	"major_unit": 2
})
chart2.set_y_axis({
	"name": "L2-norm",
	"max": 1500
})
# Add a series to the chart.
chart2.add_series({
	"name": "Non-MA",
	"categories": ["Sheet1", 1, 5, 10*NUM_PATCHES_PER_IMG*3/4+1, 5],
	"values": ["Sheet1", 1, 8, 10*NUM_PATCHES_PER_IMG*3/4+1, 8]
})
chart2.add_series({
	"name": "MA",
	"categories": ["Sheet1", 1, 15, 10*NUM_PATCHES_PER_IMG/4+1, 15],
	"values": ["Sheet1", 1, 18, 10*NUM_PATCHES_PER_IMG/4+1, 18]
})
# Insert the chart into the worksheet.
worksheet.insert_chart("D2", chart2)


# Chart 3: Freq of Maximal Intensity vs. Standard Deviation
chart3 = workbook.add_chart({
	"type": "scatter"
})
chart3.set_title({
    "name": "Freq of Maximal Intensity vs. Standard Deviation"
})
chart3.set_x_axis({
	"name": "Frequency of Maximal Intensity",
	"min": 0, 
	"max": 10,
	#"major_unit": 2
})
chart3.set_y_axis({
	"name": "Standard Deviation",
	"max": 10
})
# Add a series to the chart.
chart3.add_series({
	"name": "Non-MA",
	"categories": ["Sheet1", 1, 5, 10*NUM_PATCHES_PER_IMG*3/4+1, 5],
	"values": ["Sheet1", 1, 9, 10*NUM_PATCHES_PER_IMG*3/4+1, 9]
})
chart3.add_series({
	"name": "MA",
	"categories": ["Sheet1", 1, 15, 10*NUM_PATCHES_PER_IMG/4+1, 15],
	"values": ["Sheet1", 1, 19, 10*NUM_PATCHES_PER_IMG/4+1, 19]
})
# Insert the chart into the worksheet.
worksheet.insert_chart("E3", chart3)


# Chart 4: Standard Deviation vs. Mean Absolute Deviation
chart4 = workbook.add_chart({
	"type": "scatter"
})
chart4.set_title({
    "name": "Standard Deviation vs. Mean Absolute Deviation"
})
chart4.set_x_axis({
	"name": "Standard Deviation",
	"min": 0, 
	"max": 10,
	#"major_unit": 2
})
chart4.set_y_axis({
	"name": "Mean Absolute Deviation",
	"max": 10
})
# Add a series to the chart.
chart4.add_series({
	"name": "Non-MA",
	"categories": ["Sheet1", 1, 9, 10*NUM_PATCHES_PER_IMG*3/4+1, 9],
	"values": ["Sheet1", 1, 10, 10*NUM_PATCHES_PER_IMG*3/4+1, 10]
})
chart4.add_series({
	"name": "MA",
	"categories": ["Sheet1", 1, 20, 10*NUM_PATCHES_PER_IMG/4+1, 20],
	"values": ["Sheet1", 1, 21, 10*NUM_PATCHES_PER_IMG/4+1, 21]
})
# Insert the chart into the worksheet.
worksheet.insert_chart("F4", chart4)

workbook.close()
