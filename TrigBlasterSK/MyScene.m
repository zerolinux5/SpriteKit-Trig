//
//  MyScene.m
//  TrigBlasterSK
//
//  Created by Jesus Magana on 7/2/14.
//  Copyright (c) 2014 ZeroLinux5. All rights reserved.
//

@import CoreMotion;
@import AVFoundation;
#import "MyScene.h"

#define SK_DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) * 0.01745329252f) // PI / 180
#define SK_RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) * 57.29577951f) // PI * 180

const float MaxPlayerAccel = 400.0f;
const float MaxPlayerSpeed = 200.0f;

const float BorderCollisionDamping = 0.4f;

const int MaxHP = 100;
const float HealthBarWidth = 40.0f;
const float HealthBarHeight = 4.0f;

const float CannonCollisionRadius = 20.0f;
const float PlayerCollisionRadius = 10.0f;

const float CannonCollisionSpeed = 200.0f;

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
    
    float _playerAngle;
    float _lastAngle;
    
    SKSpriteNode *_cannonSprite;
    SKSpriteNode *_turretSprite;
    
    int _playerHP;
    int _cannonHP;
    SKNode *_playerHealthBar;
    SKNode *_cannonHealthBar;
    
    SKAction *_collisionSound;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:94.0/255.0 green:63.0/255.0 blue:107.0/255.0 alpha:1.0];
        
        _winSize = CGSizeMake(size.width, size.height);
        
        _cannonSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        _cannonSprite.position = CGPointMake(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_cannonSprite];
        
        _turretSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Turret"];
        _turretSprite.position = CGPointMake(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_turretSprite];
        
        _playerSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Player"];
        _playerSprite.position = CGPointMake(_winSize.width - 50.0f, 60.0f);
        [self addChild:_playerSprite];
        
        _motionManager = [[CMMotionManager alloc] init];
        [self startMonitoringAcceleration];
        
        _playerHealthBar = [SKNode node];
        [self addChild:_playerHealthBar];
        
        _cannonHealthBar = [SKNode node];
        [self addChild:_cannonHealthBar];
        
        _cannonHealthBar.position = CGPointMake(
                                                _cannonSprite.position.x - HealthBarWidth/2.0f + 0.5f,
                                                _cannonSprite.position.y - _cannonSprite.size.height/2.0f - 10.0f + 0.5f);
        
        _playerHP = MaxHP;
        _cannonHP = MaxHP;
        
        _collisionSound = [SKAction playSoundFileNamed:@"Collision.wav" waitForCompletion:NO];

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
    //newX = MIN(_winSize.width, MAX(newX, 0));
    //newY = MIN(_winSize.height, MAX(newY, 0));
    
    BOOL collidedWithVerticalBorder = NO;
    BOOL collidedWithHorizontalBorder = NO;
    
    if (newX < 0.0f)
    {
        newX = 0.0f;
        collidedWithVerticalBorder = YES;
    }
    else if (newX > _winSize.width)
    {
        newX = _winSize.width;
        collidedWithVerticalBorder = YES;
    }
    
    if (newY < 0.0f)
    {
        newY = 0.0f;
        collidedWithHorizontalBorder = YES;
    }
    else if (newY > _winSize.height)
    {
        newY = _winSize.height;
        collidedWithHorizontalBorder = YES;
    }
    
    if (collidedWithVerticalBorder)
    {
        _playerAccelX = -_playerAccelX * BorderCollisionDamping;
        _playerSpeedX = -_playerSpeedX * BorderCollisionDamping;
        _playerAccelY = _playerAccelY * BorderCollisionDamping;
        _playerSpeedY = _playerSpeedY * BorderCollisionDamping;
    }
    
    if (collidedWithHorizontalBorder)
    {
        _playerAccelX = _playerAccelX * BorderCollisionDamping;
        _playerSpeedX = _playerSpeedX * BorderCollisionDamping;
        _playerAccelY = -_playerAccelY * BorderCollisionDamping;
        _playerSpeedY = -_playerSpeedY * BorderCollisionDamping;
    }
    
    _playerSprite.position = CGPointMake(newX, newY);
    //float angle = atan2f(_playerSpeedY, _playerSpeedX);
    //_playerSprite.zRotation = angle - SK_DEGREES_TO_RADIANS(90);
    
    /*
    float speed = sqrtf(_playerSpeedX*_playerSpeedX + _playerSpeedY*_playerSpeedY);
    if (speed > 40.0f)
    {
        float angle = atan2f(_playerSpeedY, _playerSpeedX);
        _playerSprite.zRotation = angle - SK_DEGREES_TO_RADIANS(90.0f);
    }*/
    
    /*
    float speed = sqrtf(_playerSpeedX*_playerSpeedX + _playerSpeedY*_playerSpeedY);
    if (speed > 40.0f)
    {
        float angle = atan2f(_playerSpeedY, _playerSpeedX);
        
        const float RotationBlendFactor = 0.2f;
        _playerAngle = angle * RotationBlendFactor + _playerAngle * (1.0f - RotationBlendFactor);
    }
    
    _playerSprite.zRotation = _playerAngle - SK_DEGREES_TO_RADIANS(90.0f);
     */
    
    float speed = sqrtf(_playerSpeedX*_playerSpeedX + _playerSpeedY*_playerSpeedY);
    if (speed > 40.0f)
    {
        float angle = atan2f(_playerSpeedY, _playerSpeedX);
        
        // Did the angle flip from +Pi to -Pi, or -Pi to +Pi?
        if (_lastAngle < -3.0f && angle > 3.0f)
        {
            _playerAngle += M_PI * 2.0f;
        }
        else if (_lastAngle > 3.0f && angle < -3.0f)
        {
            _playerAngle -= M_PI * 2.0f;
        }
        
        _lastAngle = angle;
        const float RotationBlendFactor = 0.2f;
        _playerAngle = angle * RotationBlendFactor + _playerAngle * (1.0f - RotationBlendFactor);
    }
    
    _playerSprite.zRotation = _playerAngle - SK_DEGREES_TO_RADIANS(90.0f);
    
    _playerHealthBar.position = CGPointMake(
                                            _playerSprite.position.x - HealthBarWidth/2.0f + 0.5f,
                                            _playerSprite.position.y - _playerSprite.size.height/2.0f - 15.0f + 0.5f);
}

- (void)updateTurret:(NSTimeInterval)dt
{
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    float angle = atan2f(deltaY, deltaX);
    
    _turretSprite.zRotation = angle - SK_DEGREES_TO_RADIANS(90.0f);
}

-(void) drawHealthBar:(SKNode *)node withName:(NSString *)name andHealthPoints:(int)hp
{
    [node removeAllChildren];
    
    float widthOfHealth = (HealthBarWidth - 2.0f)*hp/MaxHP;
    
    UIColor *clearColor = [UIColor clearColor];
    UIColor *fillColor = [UIColor colorWithRed:113.0f/255.0f green:202.0f/255.0f blue:53.0f/255.0f alpha:1.0f];
    UIColor *borderColor = [UIColor colorWithRed:35.0f/255.0f green:28.0f/255.0f blue:40.0f/255.0f alpha:1.0f];
    
    //create the outline for the health bar
    CGSize outlineRectSize = CGSizeMake(HealthBarWidth-1.0f, HealthBarHeight-1.0);
    UIGraphicsBeginImageContextWithOptions(outlineRectSize, NO, 0.0);
    CGContextRef healthBarContext = UIGraphicsGetCurrentContext();
    
    //Drawing the outline for the health bar
    CGRect spriteOutlineRect = CGRectMake(0.0, 0.0, HealthBarWidth-1.0f, HealthBarHeight-1.0f);
    CGContextSetStrokeColorWithColor(healthBarContext, borderColor.CGColor);
    CGContextSetLineWidth(healthBarContext, 1.0);
    CGContextAddRect(healthBarContext, spriteOutlineRect);
    CGContextStrokePath(healthBarContext);
    
    //Fill the health bar with a filled rectangle
    CGRect spriteFillRect = CGRectMake(0.5, 0.5, outlineRectSize.width-1.0, outlineRectSize.height-1.0);
    spriteFillRect.size.width = widthOfHealth;
    CGContextSetFillColorWithColor(healthBarContext, fillColor.CGColor);
    CGContextSetStrokeColorWithColor(healthBarContext, clearColor.CGColor);
    CGContextSetLineWidth(healthBarContext, 1.0);
    CGContextFillRect(healthBarContext, spriteFillRect);
    
    //Generate a sprite image of the two pieces for display
    UIImage *spriteImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef spriteCGImageRef = [spriteImage CGImage];
    SKTexture *spriteTexture = [SKTexture textureWithCGImage:spriteCGImageRef];
    spriteTexture.filteringMode = SKTextureFilteringLinear; //This is the default anyway
    SKSpriteNode *frameSprite = [SKSpriteNode spriteNodeWithTexture:spriteTexture size:outlineRectSize];
    frameSprite.position = CGPointZero;
    frameSprite.name = name;
    frameSprite.anchorPoint = CGPointMake(0.0, 0.5);
    
    [node addChild:frameSprite];
}

- (void)checkCollisionOfPlayerWithCannon
{
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    
    float distance = sqrtf(deltaX*deltaX + deltaY*deltaY);
    
    if (distance <= CannonCollisionRadius + PlayerCollisionRadius)
    {
        /*
        const float CannonCollisionDamping = 0.8f;
        _playerAccelX = -_playerAccelX * CannonCollisionDamping;
        _playerSpeedX = -_playerSpeedX * CannonCollisionDamping;
        _playerAccelY = -_playerAccelY * CannonCollisionDamping;
        _playerSpeedY = -_playerSpeedY * CannonCollisionDamping;
         */
        float angle = atan2f(deltaY, deltaX);
        
        _playerSpeedX = cosf(angle) * CannonCollisionSpeed;
        _playerSpeedY = sinf(angle) * CannonCollisionSpeed;
        _playerAccelX = 0.0f;
        _playerAccelY = 0.0f;
        
        _playerHP = MAX(0, _playerHP - 20);
        _cannonHP = MAX(0, _cannonHP - 5);
        [self runAction:_collisionSound];
    }
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
    [self updateTurret:_deltaTime];
    [self checkCollisionOfPlayerWithCannon];
    [self drawHealthBar:_playerHealthBar withName:@"playerHealth" andHealthPoints:_playerHP];
    [self drawHealthBar:_cannonHealthBar withName:@"cannonHealth" andHealthPoints:_cannonHP];
}

@end
