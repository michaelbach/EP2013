/*
edgKeyConstants.h
EP2013 & ERG2007

Copyright 2009–2011 Prof. Michael Bach. All rights reserved.
 
 
History
=======

2012-07-25  Some changes to use the stimage/stimageSequence/sequenceCombination nomenclature
2012-01-11	disassociated from globals.h
 */



enum EyeCode {OD=0, OS, ONone};


// keys for the dictionary and for saving of data.
// Version of data acquisition program
#define kKeyVersion "vs"
#define kKeyEPNumber "epNum"
// block number (0=A, 1=B, …)
#define kKeyBlockNumber "blockNum"
// stimulus number, 0-xx
#define kKeySequenceNumber "sequenceNum"
// channel numbers start with 0 internally and with 1 in the user interface
#define kKeyChannel "channel"
#define kKeyDateRecording "date"
#define kKeyTimeRecording "time"
// standard sequence: surname, given name
#define kKeySubjectName "subjectName"
#define kKeyDateBorn "dateBorn"
#define kKeySubjectPIZ "subjectPIZ"
#define kKeyAcuityOD "acuityOD"
#define kKeyAcuityOS "acuityOS"
#define kKeyDoctor "physician"
#define kKeyDiagnosis "diagnosis"
#define kKeyRemark "remark"
#define kKeyEyeKey "eyeKey"
// type of EP: (P)ERG2007 / VEP / Oz, O1, …
#define kKeyEPKey "epKey"
#define kKeyPositionKey "position"
// flash strength, in cd·s/sqm
#define kKeyFlashStrength "flashStrength"
#define kKeyFlashColor "flashColor"
// flash duration in seconds
#define kKeyFlashDuration "flashDuration"
// flash luminance in cd/m²
#define kKeyFlashLuminance "flashLuminance"
// background luminance, in cd·s/sqm
#define kKeyBackgroundLuminance "backgroundLuminance"
#define kKeyBackgroundColor "backgroundColor"
#define kKeySequenceName "sequenceName"
#define kKeyCombinationName "combinationName"
#define kKeyStimNameISCEV "stimNameISCEV"
#define kKeySequenceDetails "sequenceDetails"
#define kKeyStimFrequency "frequency"

#define kKeyUnitsPerMicroVolt "unitsPerMicroVolt"

#define kKeyStimageName "stimageName"
#define kKeySymmetry "symmetry"
#define kKeyLuminance "luminance"
#define kKeyContrast "contrast"
#define kKeyFrequency "frequency"
#define kKeyElemSize "elemSize"
#define kKeyDistance "distance"
#define kKeyFramesPerImage "framesPerImage"


//onTime1:493.36;elemSize:0.209;samplesPerFrame:13.334;distance:114;"
