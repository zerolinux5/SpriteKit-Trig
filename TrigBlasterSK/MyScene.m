//
//  MyScene.m
//  TrigBlasterSK
//
//  Created by Jesus Magana on 7/2/14.
//  Copyright (c) 2014 ZeroLinux5. All rights reserved.
//

@import CoreMotion;
#import "MyScene.h"

const float MaxPlayerAccel = 400.0f;
const float MaxPlayerSpeed = 200.0f;

@implementation MyScene
{
    CGSize _winSize;
    SKSpriteNode *_playerSprite;
    UIAccelerationValue _accelerometerX;
    UIAccelerationValue _accelerometerY;
    
    
    CMMotionManager *_motionManager;
    
    float _playerAccelX;
    float _playerAccelY;
    float _playerSpeedX;
    float _playerSpeedY;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _deltaTime;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:94.0/255.0 green:63.0/255.0 blue:107.0/255.0 alpha:1.0];
        
        _winSize = CGSizeMake(size.width, size.height);
        
        _playerSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Player"];
        _playerSprite.position = CGPointMake(_winSize.width - 50.0f, 60.0f);
        [self addChild:_playerSprite];
        
        _motionManager = [[CMMotionManager alloc] init];
        [self startMonitoringAcceleration];

    }
    return self;
}

- (void)dealloc
{
    [self stopMonitoringAcceleration];
    _motionManager = nil;
}

- (void)startMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
        NSLog(@"accelerometer updates on...");
    }
}

- (void)stopMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
        [_motionManager stopAccelerometerUpdates];
        NSLog(@"accelerometer updates off...");
    }
}

- (void)updatePlayerAccelerationFromMotionManager
{
    const double FilteringFactor = 0.75;
    
    CMAcceleration acceleration = _motionManager.accelerometerData.acceleration;
    _accelerometerX = acceleration.x * FilteringFactor + _accelerometerX * (1.0 - FilteringFactor);
    _accelerometerY = acceleration.y * FilteringFactor + _accelerometerY * (1.0 - FilteringFactor);
    
    if (_accelerometerY > 0.05)
    {
        _playerAccelX = -MaxPlayerAccel;
    }
    else if (_accelerometerY < -0.05)
    {
        _playerAccelX = MaxPlayerAccel;
    }
    if (_accelerometerX < -0.05)
    {
        _playerAccelY = -MaxPlayerAccel;
    }
    else if (_accelerometerX > 0.05)
    {
        _playerAccelY = MaxPlayerAccel;
    }
    
}

- (void)updatePlayer:(NSTimeInterval)dt
{
    // 1
    _playerSpeedX += _playerAccelX * dt;
    _playerSpeedY += _playerAccelY * dt;
    
    // 2
    _playerSpeedX = fmaxf(fminf(_playerSpeedX, MaxPlayerSpeed), -MaxPlayerSpeed);
    _playerSpeedY = fmaxf(fminf(_playerSpeedY, MaxPlayerSpeed), -MaxPlayerSpeed);
    
    // 3
    float newX = _playerSprite.position.x + _playerSpeedX*dt;
    float newY = _playerSprite.position.y + _playerSpeedY*dt;
    
    // 4
    newX = MIN(_winSize.width, MAX(newX, 0));
    newY = MIN(_winSize.height, MAX(newY, 0));
    
    _playerSprite.position = CGPointMake(newX, newY);
}


-(void)update:(NSTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    //To compute velocities we need delta time to multiply by points per second
    //SpriteKit returns the currentTime, delta is computed as last called time - currentTime
    if (_lastUpdateTime) {
        _deltaTime = currentTime - _lastUpdateTime;
    } else {
        _deltaTime = 0;
    }
    _lastUpdateTime = currentTime;
    
    [self updatePlayerAccelerationFromMotionManager];
    [self updatePlayer:_deltaTime];
}

@end
