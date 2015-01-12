#import "ViewController.h"
@import AVFoundation;
@import AudioUnit;
#define kInputBus 1
AudioComponentInstance *audioUnit = NULL;
float *convertedSampleBuffer = NULL;
int status = 0;
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    AudioBufferList *bufferList;
    OSStatus status;
    status = AudioUnitRender(*audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             bufferList);
    printf("%d", status); printf("%s", " is the return code of AudioUnitRender from the recordingCallback.\n");
    // DoStuffWithTheRecordedAudio(bufferList);
    return noErr;
}
int myAudio() {
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    [mySession setCategory: AVAudioSessionCategoryRecord error: nil];
    [mySession setMode: AVAudioSessionModeMeasurement error: nil];
    [mySession setPreferredSampleRate:44100 error:nil];
    [mySession setPreferredIOBufferDuration:0.02 error:nil];
    [mySession setActive: YES error: nil];
    audioUnit = (AudioUnit*)malloc(sizeof(AudioUnit));
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    status = AudioComponentInstanceNew(comp, audioUnit);
    printf("%d", status); printf("%s", " is the return code of Instantiating a new audio component instance.\n");
    UInt32 enable = 1;
    status = AudioUnitSetProperty(*audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &enable, sizeof(enable));
    printf("%d", status); printf("%s", " is the return code of EnablingIO on the audiounit.\n");
    AudioStreamBasicDescription streamDescription = {0};
    streamDescription.mSampleRate       = 44100;
    streamDescription.mFormatID         = kAudioFormatLinearPCM;
    streamDescription.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    streamDescription.mFramesPerPacket  = 1;
    streamDescription.mChannelsPerFrame = 1;
    streamDescription.mBitsPerChannel   = 16;
    streamDescription.mBytesPerPacket   = 2;
    streamDescription.mBytesPerFrame    = 2;
    status = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamDescription, sizeof(streamDescription));
    printf("%d", status); printf("%s", " is the return code of setting the AudioStreamDescription.\n");
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = NULL;
    status = AudioUnitSetProperty(*audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    printf("%d", status); printf("%s", " is the return code of setting the recording callback on the audiounit\n");
    status = AudioUnitInitialize(*audioUnit);
    printf("%d", status); printf("%s", " is the return code of initializing the audiounit.\n");
    status = AudioOutputUnitStart(*audioUnit);
    printf("%d", status); printf("%s", " is the return code of Starting the audioUnit\n");
    return noErr;
}

@interface ViewController ()
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    myAudio();
    [NSThread sleepForTimeInterval:1];
    exit(0);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
