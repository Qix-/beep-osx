// Beep for OS X
// Adapted by Josh Junon
// Originally written by admsyn (thanks!)
// http://stackoverflow.com/a/14478420

#import <AudioToolbox/AudioToolbox.h>

#include "xopt.h"

typedef struct {
	double renderPhase;
	double frequency;
} CallbackState;

@interface Beep : NSObject
{
	AudioUnit outputUnit;
	CallbackState state;
}
@end

@implementation Beep

- (void)start: (double)frequency
{
//  First, we need to establish which Audio Unit we want.

//  We start with its description, which is:
	AudioComponentDescription outputUnitDescription = {
		.componentType         = kAudioUnitType_Output,
		.componentSubType      = kAudioUnitSubType_DefaultOutput,
		.componentManufacturer = kAudioUnitManufacturer_Apple
	};

//  Next, we get the first (and only) component corresponding to that description
	AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputUnitDescription);

//  Now we can create an instance of that component, which will create an
//  instance of the Audio Unit we're looking for (the default output)
	AudioComponentInstanceNew(outputComponent, &outputUnit);
	AudioUnitInitialize(outputUnit);

//  Next we'll tell the output unit what format our generated audio will
//  be in. Generally speaking, you'll want to stick to sane formats, since
//  the output unit won't accept every single possible stream format.
//  Here, we're specifying floating point samples with a sample rate of
//  44100 Hz in mono (i.e. 1 channel)
	AudioStreamBasicDescription ASBD = {
		.mSampleRate       = 44100,
		.mFormatID         = kAudioFormatLinearPCM,
		.mFormatFlags      = kAudioFormatFlagsNativeFloatPacked,
		.mChannelsPerFrame = 1,
		.mFramesPerPacket  = 1,
		.mBitsPerChannel   = sizeof(Float32) * 8,
		.mBytesPerPacket   = sizeof(Float32),
		.mBytesPerFrame    = sizeof(Float32)
	};

	AudioUnitSetProperty(outputUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,
						 0,
						 &ASBD,
						 sizeof(ASBD));

//  Next step is to tell our output unit which function we'd like it
//  to call to get audio samples. We'll also pass in a context pointer,
//  which can be a pointer to anything you need to maintain state between
//  render callbacks. We only need to point to a double which represents
//  the current phase of the sine wave we're creating.
	state.frequency = frequency;

	AURenderCallbackStruct callbackInfo = {
		.inputProc       = SineWaveRenderCallback,
		.inputProcRefCon = &state
	};

	AudioUnitSetProperty(outputUnit,
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Global,
						 0,
						 &callbackInfo,
						 sizeof(callbackInfo));

//  Here we're telling the output unit to start requesting audio samples
//  from our render callback. This is the line of code that starts actually
//  sending audio to your speakers.
	AudioOutputUnitStart(outputUnit);
}

// This is our render callback. It will be called very frequently for short
// buffers of audio (512 samples per call on my machine).
OSStatus SineWaveRenderCallback(void * inRefCon,
								AudioUnitRenderActionFlags * ioActionFlags,
								const AudioTimeStamp * inTimeStamp,
								UInt32 inBusNumber,
								UInt32 inNumberFrames,
								AudioBufferList * ioData)
{
	CallbackState *state = inRefCon;
	// inRefCon is the context pointer we passed in earlier when setting the render callback
	double currentPhase = state->renderPhase;
	// ioData is where we're supposed to put the audio samples we've created
	Float32 * outputBuffer = (Float32 *)ioData->mBuffers[0].mData;
	const double frequency = state->frequency;
	const double phaseStep = (frequency / 44100.) * (M_PI * 2.);

	for(int i = 0; i < inNumberFrames; i++) {
		outputBuffer[i] = sin(currentPhase);
		currentPhase += phaseStep;
	}

	// If we were doing stereo (or more), this would copy our sine wave samples
	// to all of the remaining channels
	for(int i = 1; i < ioData->mNumberBuffers; i++) {
		memcpy(ioData->mBuffers[i].mData, outputBuffer, ioData->mBuffers[i].mDataByteSize);
	}

	// writing the current phase back to inRefCon so we can use it on the next call
	state->renderPhase = currentPhase;
	return noErr;
}

- (void)stop
{
	AudioOutputUnitStop(outputUnit);
	AudioUnitUninitialize(outputUnit);
	AudioComponentInstanceDispose(outputUnit);
}

@end

typedef struct {
	bool help;
	double frequency;
	double milliseconds;
} Config;

xoptOption options[] = {
	{
		"help",
		'h',
		offsetof(Config, help),
		0,
		XOPT_TYPE_BOOL,
		0,
		"shows this message"
	},
	{
		"frequency",
		'f',
		offsetof(Config, frequency),
		0,
		XOPT_TYPE_DOUBLE,
		"N",
		"beep at N Hz"
	},
	{
		"length",
		'l',
		offsetof(Config, milliseconds),
		0,
		XOPT_TYPE_DOUBLE,
		"N",
		"beep for N milliseconds"
	},
	XOPT_NULLOPTION
};

bool parseArgs(Config *config, int argc, const char **argv) {
	const char *err = 0;

	xoptContext *ctx = xopt_context("beep", options,
			XOPT_CTX_POSIXMEHARDER | XOPT_CTX_STRICT, &err);

	if (err) {
		fprintf(stderr, "error: %s\n", err);
		return false;
	}

	const char **extras;

	xopt_parse(ctx, argc, argv, config, &extras, &err);
	if (err) {
		fprintf(stderr, "error: %s\n", err);
		free(ctx);
		return false;
	}

	if (extras) {
		free(extras); // we don't need them at the moment.
	}

	if (config->help) {
		xoptAutohelpOptions opts;
		opts.usage = "usage: beep [-f N] [-l N]";
		opts.prefix = "Plays an audible sine wave";
		opts.suffix = 0;
		opts.spacer = 10;

		xopt_autohelp(ctx, stderr, &opts, &err);

		free(ctx);
		return false;
	}

	return true;
}

int main(int argc, const char **argv) {
	Config config = {
		false,
		750.0,
		1000.0
	};

	if (!parseArgs(&config, argc, argv)) {
		return 1;
	}

	Beep *d = [[Beep alloc] init];
	[d start:config.frequency];

	usleep(config.milliseconds * 1000.0);

	[d stop];
	return 0;
}
