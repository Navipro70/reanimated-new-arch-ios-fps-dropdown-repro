#import "RCTExpandableView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <react/renderer/components/AppSpec/ComponentDescriptors.h>
#import <react/renderer/components/AppSpec/Props.h>
#import <react/renderer/components/AppSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

#pragma mark - Вспомогательные типы

struct Bezier { CGFloat x1, y1, x2, y2; };

#pragma mark - Реализация Fabric-вью

@interface RCTExpandableView () <RCTCustomExpandableViewViewProtocol>
@end

@implementation RCTExpandableView {
  // Корневой контейнер, к которому прилетает RN-стиль
  UIView *_root;
  // UI
  UIButton *_button;
  UIView *_content;
  NSLayoutConstraint *_contentHeight;

  // Состояние и анимационные параметры (мс и bezier)
  BOOL _isOpen;
  double _openDurMs;
  double _closeDurMs;
  Bezier _openCurve;
  Bezier _closeCurve;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<CustomExpandableViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setUpViews];
  }
  return self;
}

- (void)setUpViews {
  _isOpen = NO;
  _openDurMs = 320;
  _closeDurMs = 260;
  _openCurve = (Bezier){0.22, 1.0, 0.36, 1.0};
  _closeCurve = (Bezier){0.4, 0.0, 0.6, 1.0};

  _root = [UIView new];
  _root.clipsToBounds = YES;
  _root.translatesAutoresizingMaskIntoConstraints = NO;

  _button = [UIButton buttonWithType:UIButtonTypeSystem];
  _button.translatesAutoresizingMaskIntoConstraints = NO;
  [_button setTitle:@"Toggle" forState:UIControlStateNormal];
  [_button addTarget:self action:@selector(onTogglePress) forControlEvents:UIControlEventTouchUpInside];

  _content = [UIView new];
  _content.translatesAutoresizingMaskIntoConstraints = NO;
  _content.clipsToBounds = YES;

  [_root addSubview:_button];
  [_root addSubview:_content];

  [NSLayoutConstraint activateConstraints:@[
    [_button.topAnchor constraintEqualToAnchor:_root.topAnchor],
    [_button.leadingAnchor constraintEqualToAnchor:_root.leadingAnchor],
    [_button.trailingAnchor constraintEqualToAnchor:_root.trailingAnchor],
    [_button.heightAnchor constraintGreaterThanOrEqualToConstant:44.0],

    [_content.topAnchor constraintEqualToAnchor:_button.bottomAnchor],
    [_content.leadingAnchor constraintEqualToAnchor:_root.leadingAnchor],
    [_content.trailingAnchor constraintEqualToAnchor:_root.trailingAnchor],
    [_content.bottomAnchor constraintEqualToAnchor:_root.bottomAnchor],
  ]];

  _contentHeight = [_content.heightAnchor constraintEqualToConstant:0.0];
  _contentHeight.priority = UILayoutPriorityDefaultHigh;
  _contentHeight.active = YES;

  // ВАЖНО: так стиль RN попадёт на _root
  self.contentView = _root;

  // Стартовое положение всего компонента
  self.transform = _isOpen ? CGAffineTransformMakeTranslation(0.0, 500.0)
                           : CGAffineTransformIdentity;
}

#pragma mark - Кнопка

- (void)onTogglePress {
  _isOpen = !_isOpen;
  [self applyOpen:_isOpen animated:YES];
}

#pragma mark - Применение пропсов из Codegen

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &newP = *std::static_pointer_cast<CustomExpandableViewProps const>(props);
  const auto &oldP = oldProps ? *std::static_pointer_cast<CustomExpandableViewProps const>(oldProps) : newP;

  // bool
  if (oldP.isOpen != newP.isOpen) {
    _isOpen = newP.isOpen;
    [self applyOpen:_isOpen animated:YES];
  }

  // string (оставляем для совместимости; внутри не используем)
  if (oldP.title != newP.title) {
    NSString *t = [NSString stringWithUTF8String:newP.title.c_str()];
    _root.accessibilityLabel = t ?: @"";
  }

  // durations
  if (oldP.openDuration != newP.openDuration)   { _openDurMs  = (double)newP.openDuration; }
  if (oldP.closeDuration != newP.closeDuration) { _closeDurMs = (double)newP.closeDuration; }

  // beziers (ReadonlyArray<Double> длиной 4)
  if (oldP.openBezier != newP.openBezier && newP.openBezier.size() == 4) {
    _openCurve = (Bezier){ (CGFloat)newP.openBezier[0], (CGFloat)newP.openBezier[1],
                           (CGFloat)newP.openBezier[2], (CGFloat)newP.openBezier[3] };
  }
  if (oldP.closeBezier != newP.closeBezier && newP.closeBezier.size() == 4) {
    _closeCurve = (Bezier){ (CGFloat)newP.closeBezier[0], (CGFloat)newP.closeBezier[1],
                            (CGFloat)newP.closeBezier[2], (CGFloat)newP.closeBezier[3] };
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - Команды

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  if ([commandName isEqualToString:@"toggle"]) { [self onTogglePress]; return; }
  if ([commandName isEqualToString:@"open"])   { _isOpen = YES;  [self applyOpen:YES  animated:YES]; return; }
  if ([commandName isEqualToString:@"close"])  { _isOpen = NO;   [self applyOpen:NO   animated:YES]; return; }
}

#pragma mark - Анимация (только transform у self)

- (void)applyOpen:(BOOL)open animated:(BOOL)animated {
  CGAffineTransform target = open ? CGAffineTransformMakeTranslation(0.0, 500.0)
                                  : CGAffineTransformIdentity;

  if (!animated) {
    self.transform = target;
    return;
  }

  const double ms = open ? _openDurMs : _closeDurMs;
  const Bezier curve = open ? _openCurve : _closeCurve;

  if (@available(iOS 10.0, *)) {
    UICubicTimingParameters *params = [[UICubicTimingParameters alloc]
      initWithControlPoint1:CGPointMake(curve.x1, curve.y1)
               controlPoint2:CGPointMake(curve.x2, curve.y2)];

    UIViewPropertyAnimator *anim = [[UIViewPropertyAnimator alloc]
      initWithDuration:MAX(ms,0)/1000.0
      timingParameters:params];

    __weak UIView *weakView = self;
    [anim addAnimations:^{ weakView.transform = target; }];
    [anim startAnimation];
  } else {
    [UIView animateWithDuration:MAX(ms,0)/1000.0 animations:^{
      self.transform = target;
    }];
  }
}

@end
