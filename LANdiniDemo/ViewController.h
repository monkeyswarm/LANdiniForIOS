//
//  ViewController.h
//  LANdiniDemo
//
//  Created by Daniel Iglesia on 12/17/13.
//  Copyright (c) 2013 IglesiaIntermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VVOSC.h"
#import "LANdiniLANManager.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<LANdiniDemoLogDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate>{
    OSCManager *manager;
    OSCInPort *inPort;
	OSCOutPort *outPort;
}

@property (strong, nonatomic) IBOutlet UITableView* destTableView;
@property (strong, nonatomic) IBOutlet UISegmentedControl* protocolSegControl;
@property (strong, nonatomic) IBOutlet UISlider* userSlider;
@property (strong, nonatomic) IBOutlet UIButton* userSendButton;
@property (strong, nonatomic) IBOutlet UIButton* userSend100Button;
@property (strong, nonatomic) IBOutlet UIButton* userRequestTimeButton;//ipad only
@property (strong, nonatomic) IBOutlet UISlider* recSlider;
@property (strong, nonatomic) IBOutlet UISwitch* printSwitch;
@property (strong, nonatomic) IBOutlet UILabel* syncServerLabel;
@property (strong, nonatomic) IBOutlet UILabel* timeLabel;//ipad only

@property (strong, nonatomic) IBOutlet UITextView* outputLANdiniTextView;
@property (strong, nonatomic) IBOutlet UITextView* outputMsgTextView;
@property (strong, nonatomic) IBOutlet UITextView* inputLANdiniTextView;
@property (strong, nonatomic) IBOutlet UITextView* inputMsgTextView;
@end
