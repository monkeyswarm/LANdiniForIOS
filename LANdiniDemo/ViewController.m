//
//  ViewController.m
//  LANdiniDemo
//
//  Created by Daniel Iglesia on 12/17/13.
//  Copyright (c) 2013 IglesiaIntermedia. All rights reserved.
//

#import "ViewController.h"
//#import "LANdiniLANManager.h"
//#import "VVOSC.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

#define TEXT_LENGTH 2000

@interface ViewController () {
    LANdiniLANManager* llm;
    
    //my datamodel
    NSMutableArray* _userList;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _userList  = [[NSMutableArray alloc]init];
    [_userSendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchDown];
    [_userSend100Button addTarget:self action:@selector(send100Message) forControlEvents:UIControlEventTouchDown];
    [_userRequestTimeButton addTarget:self action:@selector(requestTime) forControlEvents:UIControlEventTouchDown];
    [_userSlider addTarget:self action:@selector(sendSlider) forControlEvents:UIControlEventValueChanged];
    [_printSwitch addTarget:self action:@selector(switchChange) forControlEvents:UIControlEventValueChanged];
    
    _destTableView.delegate = self;
    _destTableView.dataSource = self;

    
    llm = [[LANdiniLANManager alloc]init];
    llm.logDelegate=self;
    
    manager = [[OSCManager alloc] init];
    [manager setDelegate:self];
    int toLocalPort = 50506;
    int fromLocalPort = 50505;
    outPort = [manager createNewOutputToAddress:@"127.0.0.1" atPort:toLocalPort];
    inPort = [manager createNewInputForPort:fromLocalPort];
    
    //not called on startup
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartOSC:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopOSC:) name:UIApplicationWillResignActiveNotification object:nil];
}

-(void)restartOSC:(NSNotification*)notif{
    int toLocalPort = 50506;
    int fromLocalPort = 50505;
    outPort = [manager createNewOutputToAddress:@"127.0.0.1" atPort:toLocalPort];
    inPort = [manager createNewInputForPort:fromLocalPort];
    [llm restartOSC];
}

-(void)stopOSC:(NSNotification*)notif{
    
    [manager deleteAllOutputs];
    [manager deleteAllInputs];
    inPort = nil;
    outPort = nil;

    [llm stopOSC];
}

-(void)switchChange{
    if(![_printSwitch isOn]){
        [[_outputLANdiniTextView textStorage] replaceCharactersInRange:NSMakeRange(0, [[_outputLANdiniTextView textStorage] length]) withString:@""];
        [[_outputMsgTextView textStorage] replaceCharactersInRange:NSMakeRange(0, [[_outputMsgTextView textStorage] length]) withString:@""];
        [[_inputLANdiniTextView textStorage] replaceCharactersInRange:NSMakeRange(0, [[_inputLANdiniTextView textStorage] length]) withString:@""];
        [[_inputMsgTextView textStorage] replaceCharactersInRange:NSMakeRange(0, [[_inputMsgTextView textStorage] length]) withString:@""];
    }
}

-(NSString*)protocolString{
    switch ([_protocolSegControl selectedSegmentIndex]) {
        case 0:
            return @"/send";
        case 1:
            return @"/send/GD";
        case 2:
            return @"/send/OGD";
        default:
            return @"/send";//TODO error handle?
    }
}

-(NSString*)destString{
    NSInteger index = [_destTableView indexPathForSelectedRow].row;
    switch (index){
        case 0:return @"all";
        case 1:return @"allButMe";
        default:return [_userList objectAtIndex:index-2];
    }
}

- (void) sendMessage{//user button hit
    NSArray* msgArray =@[[self protocolString], [self destString], @"/poopy", @2, [NSNumber numberWithInteger:3]];
    [self logMsgOutput:msgArray];
    OSCMessage* msg = [LANdiniLANManager OSCMessageFromArray:msgArray];
    //[llm sendMsg:@[@"/sendGD", @"all", @"/poopy", @2]];
    [outPort sendThisPacket:[OSCPacket createWithContent:msg]];
}

- (void) send100Message{//user button hit - 100 PACKETS
    for(int i=0;i<100;i++){
        NSArray* msgArray =@[[self protocolString], [self destString], @"/lotsofmessages", [NSNumber numberWithInt:i]];
        [self logMsgOutput:msgArray];
        OSCMessage* msg = [LANdiniLANManager OSCMessageFromArray:msgArray];
        //[llm sendMsg:@[@"/sendGD", @"all", @"/poopy", @2]];
        [outPort sendThisPacket:[OSCPacket createWithContent:msg]];
    }
}

- (void) requestTime{
    NSArray* msgArray =@[ @"/networkTime" ];
    [self logMsgOutput:msgArray];
    OSCMessage* msg = [LANdiniLANManager OSCMessageFromArray:msgArray];
    [outPort sendThisPacket:[OSCPacket createWithContent:msg]];
}

- (void) sendSlider{
    NSArray* msgArray =@[[self protocolString], [self destString], @"/userSlider", [NSNumber numberWithFloat:[_userSlider value]]];
    [self logMsgOutput:msgArray];
    OSCMessage* msg = [LANdiniLANManager OSCMessageFromArray:msgArray];
    [outPort sendThisPacket:[OSCPacket createWithContent:msg]];
}

-(void)logLANdiniOutput:(NSArray*)msgArray{
    if([_printSwitch isOn]){
    dispatch_async(dispatch_get_main_queue(), ^{
        /*_outputLANdiniTextView.text = [_outputLANdiniTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n%@", [msgArray componentsJoinedByString:@", "]]];
        //if(_outputTextView )
        CGPoint bottomOffset = CGPointMake(0, [_outputLANdiniTextView contentSize].height - _outputLANdiniTextView.frame.size.height);
        [_outputLANdiniTextView setContentOffset:bottomOffset animated:YES ];*/
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat:@"\n%@", [msgArray componentsJoinedByString:@", "]]];
        
        [[_outputLANdiniTextView textStorage] appendAttributedString:attr ];
        if([[_outputLANdiniTextView textStorage] length] > TEXT_LENGTH)
           [[_outputLANdiniTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[_outputLANdiniTextView textStorage] length] - TEXT_LENGTH )];
        [_outputLANdiniTextView scrollRangeToVisible:NSMakeRange([[_outputLANdiniTextView text] length], 0)];
    });
    }
}

-(void)logMsgOutput:(NSArray*)msgArray{
    if([_printSwitch isOn]){
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat:@"\n%@", [msgArray componentsJoinedByString:@", "]]];
        [[_outputMsgTextView textStorage] appendAttributedString:attr ];
        if([[_outputMsgTextView textStorage] length] > TEXT_LENGTH)
           [[_outputMsgTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[_outputMsgTextView textStorage] length] - TEXT_LENGTH )];
        [_outputMsgTextView scrollRangeToVisible:NSMakeRange([[_outputMsgTextView text] length], 0)];
    });
    }
}

-(void)logLANdiniInput:(NSArray*)msgArray{
    if([_printSwitch isOn]){
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat:@"\n%@", [msgArray componentsJoinedByString:@", "]]];
        [[_inputLANdiniTextView textStorage] appendAttributedString:attr ];
        if([[_inputLANdiniTextView textStorage] length] > TEXT_LENGTH)
           [[_inputLANdiniTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[_inputLANdiniTextView textStorage] length] - TEXT_LENGTH )];
        [_inputLANdiniTextView scrollRangeToVisible:NSMakeRange([[_inputLANdiniTextView text] length], 0)];
    });
    }
}

-(void)logMsgInput:(NSArray*)msgArray{
    if([_printSwitch isOn]){
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat:@"\n%@", [msgArray componentsJoinedByString:@", "]]];
        [[_inputMsgTextView textStorage] appendAttributedString:attr ];
        if([[_inputMsgTextView textStorage] length] > TEXT_LENGTH)
           [[_inputMsgTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[_inputMsgTextView textStorage] length] - TEXT_LENGTH )];
        [_inputMsgTextView scrollRangeToVisible:NSMakeRange([[_inputMsgTextView text] length], 0)];
    });
    }
}

-(void) refreshSyncServer:(NSString*)newServerName{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_syncServerLabel setText:[NSString stringWithFormat:@"sync server:\n%@", newServerName]];
    });
}

- (void) receivedOSCMessage:(OSCMessage *)m	{
	//unsigned short port = [m queryTXPort];
    NSString *address = [m address];
    
    //NSMutableArray* msgArray = [[NSMutableArray alloc]init];//create blank message array for sending to pd
    NSMutableArray* tempOSCValueArray = [[NSMutableArray alloc]init];
    
    //VV library handles receiving a value confusingly: if just one value, it has a single value in message "m" and no valueArray, if more than one value, it has valuearray. here we just shove either into a temp array to iterate over
    
    if([m valueCount]==1)[tempOSCValueArray addObject:[m value]];
    else for(OSCValue *val in [m valueArray])[tempOSCValueArray addObject:val];
    
    if([address isEqualToString:@"/userSlider"]){
        dispatch_async(dispatch_get_main_queue(), ^{
        _recSlider.value = [[tempOSCValueArray objectAtIndex:0] floatValue];
        });
    }
    else if ([address isEqualToString:@"/landini/networkTime"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            float time =  [[tempOSCValueArray objectAtIndex:0] floatValue];
            [_timeLabel setText:[NSString stringWithFormat:@"%.2f sec",time]];
        });
        
    } else if ([address isEqualToString:@"/landini/numUsers"]){
        
    } else if ([address isEqualToString:@"/landini/userNames"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [_userList removeAllObjects];
            for(OSCValue* val in tempOSCValueArray){
                [_userList addObject:[val stringValue]];
            }
        
            [_destTableView reloadData];
        });
    }
    
}


//table

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 20;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyIdentifier"];
        [cell.textLabel setFont:[UIFont systemFontOfSize:18]];
    }
    
    if(indexPath.row==0)[cell.textLabel setText:@"all"];
    else if(indexPath.row==1)[cell.textLabel setText:@"allButMe"];
    else{
        NSString* name = [_userList objectAtIndex:indexPath.row-2];
        [cell.textLabel setText:name];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_userList count]+2;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
