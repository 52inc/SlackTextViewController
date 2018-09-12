//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextInputbar.h"
#import "SLKTextView.h"
#import "SLKInputAccessoryView.h"

#import "SLKTextView+SLKAdditions.h"
#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

NSString * const SLKTextInputbarDidMoveNotification =   @"SLKTextInputbarDidMoveNotification";

@interface SLKTextInputbar ()

@property (nonatomic, strong) NSLayoutConstraint *textViewBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *contentViewHC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *leftMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonTopMarginC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *editorContentViewHC;

@property (nonatomic) CGPoint previousOrigin;

@property (nonatomic, strong) Class textViewClass;

@property (nonatomic, getter=isHidden) BOOL hidden; // Required override

@end

@implementation SLKTextInputbar
@synthesize textView = _textView;
@synthesize contentView = _contentView;
@synthesize inputAccessoryView = _inputAccessoryView;
@synthesize hidden = _hidden;
@synthesize topDividerLine = _topDividerLine;

#pragma mark - Initialization

- (instancetype)initWithTextViewClass:(Class)textViewClass
{
    if (self = [super init]) {
        self.textViewClass = textViewClass;
        [self slk_commonInit];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self slk_commonInit];
    }
    return self;
}

- (void)slk_commonInit
{
    self.clipsToBounds = YES;
    self.translucent = NO;
    
    self.autoHideRightButton = NO;
    self.editorContentViewHeight = 38.0;
    self.contentInset = UIEdgeInsetsMake(0.0, 16.0, 16.0, 36.0);
    self.backgroundColor = [UIColor whiteColor];

    // Since iOS 11, it is required to call -layoutSubviews before adding custom subviews
    // so private UIToolbar subviews don't interfere on the touch hierarchy
    [self layoutSubviews];

    [self addSubview:self.editorContentView];
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    [self addSubview:self.contentView];
    [self addSubview:self.topDividerLine];

    [self slk_setupViewConstraints];
    [self slk_updateConstraintConstants];
    
    
    [self slk_registerNotifications];
    
    [self slk_registerTo:self.layer forSelector:@selector(position)];
    [self slk_registerTo:self.leftButton.imageView forSelector:@selector(image)];
    [self slk_registerTo:self.rightButton.titleLabel forSelector:@selector(font)];
}


#pragma mark - UIView Overrides

- (void) drawRect:(CGRect)rect {
    
//    CGFloat gradientDistance = 15.0;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
//
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGFloat colorStops[] = {0.1, 1.0};
//    NSArray *colors = @[(id)[[UIColor colorWithWhite:1.0 alpha:0.0] CGColor], (id)[[UIColor whiteColor] CGColor]];
//
//    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, colorStops);
//
//    CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0, 0.0), CGPointMake(0.0, gradientDistance), 0);
//
//    [[UIColor colorWithWhite:1.0 alpha:1.0] set];
//    CGContextFillRect(context, CGRectMake(CGRectGetMinX(rect), gradientDistance, CGRectGetWidth(rect), CGRectGetHeight(rect) - gradientDistance));
//
//    CGColorSpaceRelease(colorSpace);
    
    [[UIColor colorWithWhite:1.0 alpha:1.0] set];
    CGContextFillRect(context, rect);

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.5, 0.5);
    
    CGFloat leftSafeArea = 0.0;
    CGFloat rightSafeArea = 0.0;

    if (@available(iOS 11.0, *)) {
        leftSafeArea = [self safeAreaInsets].left;
        rightSafeArea = [self safeAreaInsets].right;
    }
    
    CGRect textBoxRect = CGRectMake(leftSafeArea + 16.0, 0, CGRectGetWidth(rect) - 32.0 - leftSafeArea - rightSafeArea, CGRectGetHeight(rect) - 16.0);
    [[UIColor colorWithRed:229.0/255.0 green:231.0/255.0 blue:235.0/255.0 alpha:1.0] set];
    CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:textBoxRect cornerRadius:4.0] CGPath];
    
    CGContextAddPath(context, path);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);
    
    CGFloat dividerLineHeight = 32.0;
    CGFloat dividerLineDistanceFromBottomOfTextBox = 12.0;
    CGFloat distanceBetweenButtons = 44.0;
    
    CGContextMoveToPoint(context, CGRectGetMaxX(rect) - [self slk_appropriateRightButtonMargin] - CGRectGetWidth([self rightButton].bounds) - (distanceBetweenButtons / 2.0), CGRectGetMaxY(textBoxRect) - dividerLineDistanceFromBottomOfTextBox);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect) - [self slk_appropriateRightButtonMargin] - CGRectGetWidth([self rightButton].bounds) - (distanceBetweenButtons / 2.0), CGRectGetMaxY(textBoxRect) - dividerLineHeight - dividerLineDistanceFromBottomOfTextBox);
    
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

- (void)layoutIfNeeded
{
    if (self.constraints.count == 0 || !self.window) {
        return;
    }
    
    [self slk_updateConstraintConstants];
    [super layoutIfNeeded];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    
    [self slk_updateConstraintConstants];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [self minimumInputbarHeight]);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}


#pragma mark - Getters

- (SLKTextView *)textView
{
    if (!_textView) {
        Class class = self.textViewClass ? : [SLKTextView class];
        
        _textView = [[class alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0];
        _textView.maxNumberOfLines = [self slk_defaultNumberOfLines];
        
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, -1.0, 0.0, 1.0);
        _textView.textContainerInset = UIEdgeInsetsMake(19.0, 9.0, 19.0, 0.0);
        _textView.backgroundColor = [UIColor clearColor];
        _textView.showsVerticalScrollIndicator = NO;
    }
    return _textView;
}

- (UIView *)topDividerLine
{
    if (!_topDividerLine) {
        _topDividerLine = [UIView new];
        _topDividerLine.hidden = YES;
        _topDividerLine.translatesAutoresizingMaskIntoConstraints = NO;
        _topDividerLine.backgroundColor = [UIColor clearColor];// [UIColor colorWithRed:229.0/255.0 green:231.0/255.0 blue:235.0/255.0 alpha:1.0];
    }
    return _topDividerLine;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}

- (SLKInputAccessoryView *)inputAccessoryView
{
    if (!_inputAccessoryView) {
        _inputAccessoryView = [[SLKInputAccessoryView alloc] initWithFrame:CGRectZero];
        _inputAccessoryView.backgroundColor = [UIColor clearColor];
        _inputAccessoryView.userInteractionEnabled = NO;
    }
    
    return _inputAccessoryView;
}

- (UIButton *)leftButton
{
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _rightButton.enabled = NO;
        
        NSString *title = NSLocalizedString(@"Send", nil);
        
        [_rightButton setTitle:title forState:UIControlStateNormal];
    }
    return _rightButton;
}

- (UIView *)editorContentView
{
    if (!_editorContentView) {
        _editorContentView = [UIView new];
        _editorContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _editorContentView.backgroundColor = self.backgroundColor;
        _editorContentView.clipsToBounds = YES;
        _editorContentView.hidden = YES;
        
        [_editorContentView addSubview:self.editorTitle];
        [_editorContentView addSubview:self.editorLeftButton];
        [_editorContentView addSubview:self.editorRightButton];
        
        NSDictionary *views = @{@"label": self.editorTitle,
                                @"leftButton": self.editorLeftButton,
                                @"rightButton": self.editorRightButton,
                                };
        
        NSDictionary *metrics = @{@"left" : @(self.contentInset.left),
                                  @"right" : @(self.contentInset.right)
                                  };
        
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[leftButton(60)]-(left)-[label(>=0)]-(right)-[rightButton(60)]-(<=right)-|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
    }
    return _editorContentView;
}

- (UILabel *)editorTitle
{
    if (!_editorTitle) {
        _editorTitle = [UILabel new];
        _editorTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _editorTitle.textAlignment = NSTextAlignmentCenter;
        _editorTitle.backgroundColor = [UIColor clearColor];
        _editorTitle.font = [UIFont boldSystemFontOfSize:15.0];
        
        NSString *title = NSLocalizedString(@"Editing Message", nil);
        
        _editorTitle.text = title;
    }
    return _editorTitle;
}

- (UIButton *)editorLeftButton
{
    if (!_editorLeftButton) {
        _editorLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editorLeftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editorLeftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _editorLeftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        
        NSString *title = NSLocalizedString(@"Cancel", nil);
        
        [_editorLeftButton setTitle:title forState:UIControlStateNormal];
    }
    return _editorLeftButton;
}

- (UIButton *)editorRightButton
{
    if (!_editorRightButton) {
        _editorRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editorRightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editorRightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _editorRightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _editorRightButton.enabled = NO;
        
        NSString *title = NSLocalizedString(@"Save", nil);
        
        [_editorRightButton setTitle:title forState:UIControlStateNormal];
    }
    return _editorRightButton;
}

- (BOOL)isHidden
{
    return _hidden;
}

- (CGFloat)minimumInputbarHeight
{
    CGFloat minimumHeight = self.textView.intrinsicContentSize.height;
    minimumHeight += self.contentInset.top;
    minimumHeight += self.slk_bottomMargin;
    
    return minimumHeight;
}

- (CGFloat)appropriateHeight
{
    CGFloat height = 0.0;
    CGFloat minimumHeight = [self minimumInputbarHeight];
    
    if (self.textView.numberOfLines == 1) {
        height = minimumHeight;
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height = [self slk_inputBarHeightForLines:self.textView.numberOfLines];
    }
    else {
        height = [self slk_inputBarHeightForLines:self.textView.maxNumberOfLines];
    }
    
    if (height < minimumHeight) {
        height = minimumHeight;
    }
    
    if (self.isEditing) {
        height += self.editorContentViewHeight;
    }
        
    return roundf(height);
}

- (CGFloat)slk_inputBarHeightForLines:(NSUInteger)numberOfLines
{
    CGFloat height = self.textView.intrinsicContentSize.height;
    height -= self.textView.font.lineHeight;
    height += roundf(self.textView.font.lineHeight*numberOfLines);
    height += self.contentInset.top;
    height += self.slk_bottomMargin;
    
    return height;
}

- (CGFloat)slk_bottomMargin
{
    CGFloat margin = self.contentInset.bottom;
    margin += self.slk_contentViewHeight;
    
    return margin;
}

- (CGFloat)slk_contentViewHeight
{
    if (!self.editing) {
        return CGRectGetHeight(self.contentView.frame);
    }
    
    return 0.0;
}

- (CGFloat)slk_appropriateRightButtonWidth
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }

    return [self.rightButton intrinsicContentSize].width;
}

- (CGFloat)slk_appropriateRightButtonMargin
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    
    CGFloat safeArea = 0.0;
    
    if (@available(iOS 11.0, *)) {
        safeArea = [self safeAreaInsets].right;
    }
    
    return self.contentInset.right + safeArea;
}

- (CGFloat)slk_appropriateLeftTextViewMargin
{
    CGFloat safeArea = 0.0;
    
    if (@available(iOS 11.0, *)) {
        safeArea = [self safeAreaInsets].right;
    }
    
    return self.contentInset.left + safeArea;
}

- (NSUInteger)slk_defaultNumberOfLines
{
    if (SLK_IS_IPAD) {
        return 8;
    }
    else if (SLK_IS_IPHONE4) {
        return 4;
    }
    else {
        return 6;
    }
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;

    self.editorContentView.backgroundColor = color;
}

- (void)setAutoHideRightButton:(BOOL)hide
{
    if (self.autoHideRightButton == hide) {
        return;
    }
    
    _autoHideRightButton = hide;
    
    self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
    self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];

    [self layoutIfNeeded];
}

- (void)setContentInset:(UIEdgeInsets)insets
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, insets)) {
        return;
    }
    
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, UIEdgeInsetsZero)) {
        _contentInset = insets;
        return;
    }
    
    _contentInset = insets;
    
    // Add new constraints
    [self removeConstraints:self.constraints];
    [self slk_setupViewConstraints];
    
    // Add constant values and refresh layout
    [self slk_updateConstraintConstants];
    
    [super layoutIfNeeded];
}

- (void)setEditing:(BOOL)editing
{
    if (self.isEditing == editing) {
        return;
    }
    
    _editing = editing;
    _editorContentView.hidden = !editing;
    
    self.contentViewHC.active = editing;
    
    [super setNeedsLayout];
    [super layoutIfNeeded];
}

- (void)setHidden:(BOOL)hidden
{
    // We don't call super here, since we want to avoid to visually hide the view.
    // The hidden render state is handled by the view controller.
    
    _hidden = hidden;
    
    if (!self.isEditing) {
        self.contentViewHC.active = hidden;
        
        [super setNeedsLayout];
        [super layoutIfNeeded];
    }
}

#pragma mark - Text Editing

- (BOOL)canEditText:(NSString *)text
{
    if ((self.isEditing && [self.textView.text isEqualToString:text]) || self.isHidden) {
        return NO;
    }
    
    return YES;
}

- (void)beginTextEditing
{
    if (self.isEditing || self.isHidden) {
        return;
    }
    
    self.editing = YES;
    
    [self slk_updateConstraintConstants];
    
    if (!self.isFirstResponder) {
        [self layoutIfNeeded];
    }
}

- (void)endTextEdition
{
    if (!self.isEditing || self.isHidden) {
        return;
    }
    
    self.editing = NO;
    
    [self slk_updateConstraintConstants];
}

#pragma mark - Notification Events

- (void)slk_didChangeTextViewText:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    if (self.autoHideRightButton && !self.isEditing)
    {
        CGFloat rightButtonNewWidth = [self slk_appropriateRightButtonWidth];
        
        // Only updates if the width did change
        if (self.rightButtonWC.constant == rightButtonNewWidth) {
            return;
        }
        
        self.rightButtonWC.constant = rightButtonNewWidth;
        self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];
        [self.rightButton layoutIfNeeded]; // Avoids the right button to stretch when animating the constraint changes
        
        BOOL bounces = self.bounces && [self.textView isFirstResponder];
        
        if (self.window) {
            [self slk_animateLayoutIfNeededWithBounce:bounces
                                              options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                                           animations:NULL];
        }
        else {
            [self layoutIfNeeded];
        }
    }
}

- (void)slk_didChangeTextViewContentSize:(NSNotification *)notification
{ }

- (void)slk_didChangeContentSizeCategory:(NSNotification *)notification
{
    if (!self.textView.isDynamicTypeEnabled) {
        return;
    }
    
    [self layoutIfNeeded];
}


#pragma mark - View Auto-Layout

- (void)slk_setupViewConstraints
{
    NSDictionary *views = @{@"textView": self.textView,
                            @"leftButton": self.leftButton,
                            @"rightButton": self.rightButton,
                            @"editorContentView": self.editorContentView,
                            @"contentView": self.contentView,
                            @"topDivider" : self.topDividerLine
                            };
    
    NSDictionary *metrics = @{@"top" : @(self.contentInset.top),
                              @"left" : @([self slk_appropriateLeftTextViewMargin]),
                              @"right" : @(self.contentInset.right),
                              @"buttonSpacing" : @(44.0),
                              @"messageBoxRightSpacing" : @(8.0)
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[textView]-(messageBoxRightSpacing)-[leftButton(0)]-(buttonSpacing@750)-[rightButton(0)]-(right)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[rightButton]-(<=0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[topDivider]-(0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[topDivider(1@750)]-(>=0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[editorContentView(0)]-(<=top)-[textView(0@999)]-(0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[editorContentView]|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView(0)]|" options:0 metrics:metrics views:views]];

    self.textViewBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.textView];
    self.editorContentViewHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.editorContentView secondItem:nil];
    self.contentViewHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.contentView secondItem:nil];;
    self.contentViewHC.active = NO; // Disabled by default, so the height is calculated with the height of its subviews
    
    self.leftButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.leftButton secondItem:nil];
    self.leftButtonHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.leftButton secondItem:nil];
    self.leftButtonBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.leftButton];

    self.leftMarginWC = [[self slk_constraintsForAttribute:NSLayoutAttributeLeading] firstObject];
    
    self.rightButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.rightButton secondItem:nil];
    self.rightMarginWC = [[self slk_constraintsForAttribute:NSLayoutAttributeTrailing] firstObject];
    
    self.rightButtonTopMarginC = [self slk_constraintForAttribute:NSLayoutAttributeTop firstItem:self.rightButton secondItem:self];
    self.rightButtonBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.rightButton];
}

- (void)slk_updateConstraintConstants
{
    CGFloat zero = 0.0;
    
    self.textViewBottomMarginC.constant = self.slk_bottomMargin;

    if (self.isEditing)
    {
        self.editorContentViewHC.constant = self.editorContentViewHeight;
        
        self.leftButtonWC.constant = zero;
        self.leftButtonHC.constant = zero;
        self.leftMarginWC.constant = zero;
        self.leftButtonBottomMarginC.constant = zero;
        self.rightButtonWC.constant = zero;
        self.rightMarginWC.constant = zero;
    }
    else {
        self.editorContentViewHC.constant = zero;
        
        CGSize leftButtonSize = [self.leftButton imageForState:self.leftButton.state].size;
        
        if (leftButtonSize.width > 0) {
            self.leftButtonHC.constant = roundf(leftButtonSize.height);
            self.leftButtonBottomMarginC.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0) + (self.slk_contentViewHeight / 2.0) + 8.0;
        }
        
        self.leftButtonWC.constant = roundf(leftButtonSize.width);
        self.leftMarginWC.constant = [self slk_appropriateLeftTextViewMargin];
        
        self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
        self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];
        
        CGFloat rightVerMargin = (self.intrinsicContentSize.height - self.slk_contentViewHeight - self.rightButton.intrinsicContentSize.height) / 2.0;
        CGFloat rightVerBottomMargin = rightVerMargin + self.slk_contentViewHeight;
        
        self.rightButtonTopMarginC.constant = rightVerMargin - 8.0;
        self.rightButtonBottomMarginC.constant = rightVerBottomMargin + 8.0;
    }
}


#pragma mark - Observers

- (void)slk_registerTo:(id)object forSelector:(SEL)selector
{
    if (object) {
        [object addObserver:self forKeyPath:NSStringFromSelector(selector) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

- (void)slk_unregisterFrom:(id)object forSelector:(SEL)selector
{
    if (object) {
        [object removeObserver:self forKeyPath:NSStringFromSelector(selector)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.layer] && [keyPath isEqualToString:NSStringFromSelector(@selector(position))]) {
        
        if (!CGPointEqualToPoint(self.previousOrigin, self.frame.origin)) {
            self.previousOrigin = self.frame.origin;
            [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextInputbarDidMoveNotification object:self userInfo:@{@"origin": [NSValue valueWithCGPoint:self.previousOrigin]}];
        }
    }
    else if ([object isEqual:self.leftButton.imageView] && [keyPath isEqualToString:NSStringFromSelector(@selector(image))]) {
        
        UIImage *newImage = change[NSKeyValueChangeNewKey];
        UIImage *oldImage = change[NSKeyValueChangeOldKey];
        
        if (![newImage isEqual:oldImage]) {
            [self slk_updateConstraintConstants];
        }
    }
    else if ([object isEqual:self.rightButton.titleLabel] && [keyPath isEqualToString:NSStringFromSelector(@selector(font))]) {
        
        [self slk_updateConstraintConstants];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - NSNotificationCenter registration

- (void)slk_registerNotifications
{
    [self slk_unregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeContentSizeCategory:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)slk_unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [self slk_unregisterNotifications];
    
    [self slk_unregisterFrom:self.layer forSelector:@selector(position)];
    [self slk_unregisterFrom:self.leftButton.imageView forSelector:@selector(image)];
    [self slk_unregisterFrom:self.rightButton.titleLabel forSelector:@selector(font)];
}

@end
