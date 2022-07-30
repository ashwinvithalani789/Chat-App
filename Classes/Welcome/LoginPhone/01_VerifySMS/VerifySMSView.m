//
// Copyright (c) 2018 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VerifySMSView.h"


//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface VerifySMSView()
{
	NSString *countryCode;
	NSString *phoneNumber;
	id<SINVerification> verification;
}

@property (strong, nonatomic) IBOutlet UILabel *labelHeader;
@property (strong, nonatomic) IBOutlet UITextField *fieldCode;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation VerifySMSView

@synthesize delegate;
@synthesize labelHeader, fieldCode;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)countryCode_ phoneNumber:(NSString *)phoneNumber_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	countryCode = countryCode_;
	phoneNumber = phoneNumber_;
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"SMS Verification";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionDismissFailed)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.view addGestureRecognizer:gestureRecognizer];
	gestureRecognizer.cancelsTouchesInView = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelHeader.text = [NSString stringWithFormat:@"Enter the verification code sent to\n\n%@ %@", countryCode, phoneNumber];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self verifyNumber];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[fieldCode becomeFirstResponder];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillDisappear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self dismissKeyboard];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)dismissKeyboard
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
}

#pragma mark - Sinch methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)verifyNumber
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSError *error = nil;
	NSString *defaultRegion = [SINDeviceRegion currentCountryCode];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *number = [NSString stringWithFormat:@"%@%@", countryCode, phoneNumber];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	id<SINPhoneNumber> tempNumber = [SINPhoneNumberUtil() parse:number defaultRegion:defaultRegion error:&error];
	if (error == nil)
	{
		NSString *phoneNumberInE164 = [SINPhoneNumberUtil() formatNumber:tempNumber format:SINPhoneNumberFormatE164];
		verification = [SINVerification SMSVerificationWithApplicationKey:SINCH_KEY phoneNumber:phoneNumberInE164];
		[verification initiateWithCompletionHandler:^(id<SINInitiationResult> result, NSError *error)
		{
			if (error != nil) [self actionDismissFailed];
		}];
	}
	else [self actionDismissFailed];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)verifyCode:(NSString *)code
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissKeyboard];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[ProgressHUD show:nil Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[verification verifyCode:code completionHandler:^(BOOL success, NSError *error)
	{
		if (success == NO)
		{
			[ProgressHUD showError:@"The entered code is invalid."];
			[fieldCode becomeFirstResponder];
		}
		else [self actionDismissSucceed];
	}];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDismissSucceed
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:^{
		if (delegate != nil) [delegate verifySMSSucceed];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDismissFailed
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:^{
		if (delegate != nil) [delegate verifySMSFailed];
	}];
}

#pragma mark - UITextFieldDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *code = [textField.text stringByReplacingCharactersInRange:range withString:string];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([code length] == 4)
	{
		dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
		dispatch_after(time, dispatch_get_main_queue(), ^{ [self verifyCode:code]; });
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return ([code length] <= 4);
}

@end

