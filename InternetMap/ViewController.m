//
//  ViewController.m
//  InternetMap
//

#import "ViewController.h"
#import "MapDisplay.h"
#import "MapData.h"

@interface ViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.preferredFramesPerSecond = 60.0f;

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:self.context];
    
    self.display = [MapDisplay new];
    self.data = [MapData new];
    
    [self.data loadFromFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]];
    [self.data updateDisplay:self.display];
}

- (void)dealloc
{    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.display.size = self.view.bounds.size;
    
    [self.display update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    static int count = 0;
    count++;
    if(count == 30) {
        count = 0;
        NSLog(@"%.2f", self.timeSinceLastDraw * 1000);
    }
    
    [self.display draw];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    float deltaX = [touch locationInView:self.view].x - [touch previousLocationInView:self.view].x;
    float deltaY = [touch locationInView:self.view].y - [touch previousLocationInView:self.view].y;
    
    [self.display rotateRadiansX:deltaX * 0.01];
    [self.display rotateRadiansY:deltaY * 0.01];
}
    
@end
