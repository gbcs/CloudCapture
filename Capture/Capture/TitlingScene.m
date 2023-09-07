//
//  TitlingScene.m
//  Capture
//
//  Created by Gary Barnett on 8/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "TitlingScene.h"

@implementation TitlingScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:0 green:0 blue:0 alpha:0.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Hello, World!";
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
        
        sprite.position = CGPointMake(300,150);
        
        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
        
        [sprite runAction:[SKAction repeatActionForever:action]];
        
        SKTexture *t = [SKTexture ]
        
        SKSpriteNode *videoSprite = [SKSpriteNode spriteNodeWithTexture:<#(SKTexture *)#> size:<#(CGSize)#>]
        
        
        [self addChild:sprite];

        [self addChild:myLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
          }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
