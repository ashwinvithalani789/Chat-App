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

#import "LoginPhoneView.h"
#import "NavigationController.h"


//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface LoginPhoneView()
{
	UIBarButtonItem *buttonRight;
}

@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UILabel *labelCode;
@property (strong, nonatomic) IBOutlet UITextField *fieldPhone;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation LoginPhoneView

@synthesize delegate;
@synthesize labelName, labelCode, fieldPhone;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"Phone Login";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	buttonRight = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(actionNext)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.view addGestureRecognizer:gestureRecognizer];
	gestureRecognizer.cancelsTouchesInView = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSMutableArray *countries = [[NSMutableArray alloc] initWithContentsOfFile:[Dir application:@"countries.plist"]];
	NSDictionary *country = countries[DEFAULT_COUNTRY];
	labelName.text = country[@"name"];
	labelCode.text = country[@"dial_code"];
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

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCancel
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionNext
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	VerifySMSView *verifySMSView = [[VerifySMSView alloc] initWith:labelCode.text phoneNumber:fieldPhone.text];
	verifySMSView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:verifySMSView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionCountries:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	CountriesView *countriesView = [[CountriesView alloc] init];
	countriesView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:countriesView];
	[self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - VerifySMSDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)verifySMSSucceed
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *phone = [NSString stringWithFormat:@"%@%@", labelCode.text, fieldPhone.text];
	NSCharacterSet *restricted = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	NSString *numbers = [[phone componentsSeparatedByCharactersInSet:restricted] componentsJoinedByString:@""];
	NSString *email = [NSString stringWithFormat:@"%@@%@", numbers, PHONE_LOGIN_DOMAIN];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self actionLogin:email password:PHONE_LOGIN_PASSWORD];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)verifySMSFailed
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD showError:@"SMS verification failed."];
}

#pragma mark - CountriesDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectCountry:(NSString *)country CountryCode:(NSString *)countryCode
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelName.text = country;
	labelCode.text = countryCode;
	[fieldPhone becomeFirstResponder];
}

#pragma mark - Login, Register methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionLogin:(NSString *)email password:(NSString *)password
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD show:nil Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[FUser signInWithEmail:email password:password completion:^(FUser *user, NSError *error)
	{
		if (error == nil)
		{
			[self dismissViewControllerAnimated:YES completion:^{
				if (delegate != nil) [delegate didLoginPhone];
			}];
		}
		else [self actionRegister:email password:password];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionRegister:(NSString *)email password:(NSString *)password
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[FUser createUserWithEmail:email password:password completion:^(FUser *user, NSError *error)
	{
		if (error == nil)
		{
			[self saveUserPhone];
			[self dismissViewControllerAnimated:YES completion:^{
				if (delegate != nil) [delegate didLoginPhone];
			}];
		}
		else [ProgressHUD showError:[error description]];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)saveUserPhone
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FUser *user = [FUser currentUser];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	user[FUSER_PHONE] = [NSString stringWithFormat:@"%@%@", labelCode.text, fieldPhone.text];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[user saveInBackground:^(NSError *error)
	{
		if (error != nil) [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - UITextFieldDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *phone = [textField.text stringByReplacingCharactersInRange:range withString:string];
	self.navigationItem.rightBarButtonItem = ([phone length] != 0) ? buttonRight : nil;
	return YES;
}

@end

