 DiaRetDB1 - Diabetic Retinopathy Database and Evaluation Protocol
                        Version 2.1


Authors*: Joni Kämäräinen <joni.kamarainen@lut.fi>
	  Lasse Lensu <lasse.lensu@lut.fi>

 *These are the contact authors on behalf of all authors

Website: http://www.it.lut.fi/project/imageret/diaretdb1_v2_1/

A document describing the contents of the database (directory structure) and
functions related to usage of the database (provided as a separate package).

For more information and the copyright and license terms refer to the
Website.

Contents
1. Directory structure and files


                        --- 1. DIRECTORY STRUCTURE AND FILES ---
   [Files]

README.txt - This file

ddb1_v02_01_train.txt - Standard list of images and corresponding ground
truth files used for training. Paths related to the installation directory
of the database:
images/<IMGFILE1> groundtruth/<IMGFILE1>_01.xml groundtruth/<IMGFILE1>_02.xml ...
images/<IMGFILE2> groundtruth/<IMGFILE2>_01.xml groundtruth/<IMGFILE2>_02.xml ...

ddb1_v02_01_train_plain.txt - Same as the ddb1_v02_01_train.txt, but the
ground truth refers to the plain xml files (e.g. <IMGFILE_01_plain.xml),
which can be loaded without connection to the server containing the
XML-description.

ddb1_v02_01_test.txt
db1_v02_01_test_plain.txt - Same as the previous, but for testing (tot. of
61 images).


   [Directories]

groundtruth/ - XML-files containing expert annotated ground truths. Several
independent annotation files per each image.


images/ - 89 fundus images (PPM format).


                        --- 2. DATA I/O FUNCTIONALITY ---

Transformed to a separate package for easier management. See the database
web page.