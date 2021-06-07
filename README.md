# ImaLife Air-Flow Pipeline

-------------------

## Introduction
This repo combines a number of tools into an automated process for the
extraction and measurement of bronchial parameters on a low-dose CT scan.

It combines the 3D-Unet method [bronchinet](/bronchinet) to obtain the initial airway lumen segmentation.
This is followed by the [Opfront](/opfront) method which uses optimal-surface graph-cut to separate the inner surface of the airway from the outer surface of the airway.
From this, various bronchial parameters can be derived.
