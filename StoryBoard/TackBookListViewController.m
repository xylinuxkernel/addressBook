//
//  TackBookListViewController.m
//  ksky
//
//  Created by 徐银 on 15/11/21.
//  Copyright © 2015年 徐银. All rights reserved.
//

#import "TackBookListViewController.h"
#import  <AddressBook/AddressBook.h>
#import "AddressBook.h"
//#import "CMCommonUtility.h"
#import "pinyin.h"
@interface TackBookListViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray * addressBookTemp;
    NSMutableArray * allKeys;
    NSMutableArray *contentArr;
}
@property (nonatomic,strong) UITableView *tableView;
@end

@implementation TackBookListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    addressBookTemp = [[NSMutableArray alloc]initWithCapacity:5];
    [self getAllContackList];
    CGRect frame = self.view.frame;
    self.tableView = [[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource =self;
    // Do any additional setup after loading the view.
}

-(void)getAllContackList
{
    /*通过通讯录分享*/
    ABAddressBookRef addressBooks = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBooks =  ABAddressBookCreateWithOptions(NULL, NULL);
        //获取通讯录权限
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBooks, ^(bool granted, CFErrorRef error){dispatch_semaphore_signal(sema);});
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else
    {
        addressBooks = ABAddressBookCreate();
        
    }
    
    //获取通讯录中的所有人
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBooks);
    //通讯录中人数
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBooks);
    
    //循环，获取每个人的个人信息
    for (NSInteger i = 0; i < nPeople; i++)
    {
        //新建一个addressBook model类
        AddressBook *addressBook = [[AddressBook alloc] init];
        //获取个人
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        //获取个人名字
        CFTypeRef abName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        CFTypeRef abLastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
        CFStringRef abFullName = ABRecordCopyCompositeName(person);
        NSString *nameString = (__bridge NSString *)abName;
        NSString *lastNameString = (__bridge NSString *)abLastName;
        
        if ((__bridge id)abFullName != nil) {
            nameString = (__bridge NSString *)abFullName;
        } else {
            if ((__bridge id)abLastName != nil)
            {
                nameString = [NSString stringWithFormat:@"%@ %@", nameString, lastNameString];
            }
        }
        addressBook.name = nameString;
        ABPropertyID multiProperties[] = {
            kABPersonPhoneProperty,
            kABPersonEmailProperty
        };
        NSInteger multiPropertiesTotal = sizeof(multiProperties) / sizeof(ABPropertyID);
        for (NSInteger j = 0; j < multiPropertiesTotal; j++) {
            ABPropertyID property = multiProperties[j];
            ABMultiValueRef valuesRef = ABRecordCopyValue(person, property);
            NSInteger valuesCount = 0;
            if (valuesRef != nil) valuesCount = ABMultiValueGetCount(valuesRef);
            
            if (valuesCount == 0) {
                CFRelease(valuesRef);
                continue;
            }
            //获取电话号码和email
            for (NSInteger k = 0; k < valuesCount; k++) {
                CFTypeRef value = ABMultiValueCopyValueAtIndex(valuesRef, k);
                switch (j) {
                    case 0: {// Phone number
                        addressBook.tel = (__bridge NSString*)value;
                        break;
                    }
                }
                CFRelease(value);
            }
            CFRelease(valuesRef);
        }
        if (addressBook.tel) {
            [addressBookTemp addObject:addressBook];
        }
        
        if (abName) CFRelease(abName);
        if (abLastName) CFRelease(abLastName);
        if (abFullName) CFRelease(abFullName);
    }
    [self sortAllkey];
}

//排序分组
-(void)sortAllkey
{
    allKeys = [[NSMutableArray alloc]init];
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    //获取第一个字母到key中
    for (AddressBook *addressBook in addressBookTemp) {
        if (addressBook.name&&![addressBook.name isEqualToString:@""]) {
            NSString *key=[[NSString stringWithFormat:@"%c",pinyinFirstLetter([addressBook.name characterAtIndex:0])]uppercaseString];
            if (![tempArr containsObject:key]) {
                [tempArr addObject:key];
            }
        }
    }
    //字母排序
   [allKeys = tempArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
       NSString *result1 = (NSString *)obj1;
       NSString *result2 = (NSString *)obj2;
       return [result1 compare:result2]==NSOrderedDescending;
   }];
  //根据第一个字母到
    contentArr = [[NSMutableArray alloc]init];
    for(NSString *key in allKeys)
    {
        NSMutableArray *tempContent = [[NSMutableArray alloc]init];
        for (int j = 0; j < [addressBookTemp count]; j++) {
            AddressBook*addresBook = (AddressBook*)addressBookTemp[j];
            NSString *keyTemp=[[NSString stringWithFormat:@"%c",pinyinFirstLetter([addresBook.name characterAtIndex:0])]uppercaseString];
            if ([keyTemp isEqualToString:key]) {
                [tempContent addObject:addresBook];
            }
        }
        [contentArr addObject:tempContent];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [allKeys count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [contentArr[section] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return allKeys[section];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return allKeys;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:identifier];
      
    }
    AddressBook *bookModel = (contentArr[indexPath.section])[indexPath.row];
    cell.textLabel.text = bookModel.name;
    cell.detailTextLabel.text = @"邀请";
    cell.detailTextLabel.textColor = [UIColor blueColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AddressBook *bookModel = addressBookTemp[indexPath.row];
//    [self showMessageViewController:bookModel];
    
}

#if 0
-(void)showMessageViewController:(AddressBook *)reci
{
    if( [MFMessageComposeViewController canSendText] )//判断是否能发短息
    {
        
//        MFMessageComposeViewController * controller = [[MFMessageComposeViewController alloc]init];
//        controller.recipients = [NSArray arrayWithObject:reci.tel];
//        controller.navigationBar.tintColor = [UIColor redColor];
//        controller.body = @"测试消息来自ksky";//短信内容,自定义即可
//        controller.messageComposeDelegate = self;//注意不是delegate
//        
//        [self presentViewController:controller animated:YES completion:nil];
//        
//        [[[[controller viewControllers] lastObject] navigationItem] setTitle:reci.tel];
        [CMCommonUtility sendSMS:@"测试消息来自ksky" recipientList:@[reci.tel] byViewController:self ];

    }
    else
    {
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"抱歉" message:@"短信功能不可用!" delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil,nil];
        [alert show];
    }
}

//短信发送成功后的回调
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    switch (result)
    {
        case MessageComposeResultCancelled:
        {
            //用户取消发送
        }
            break;
        case MessageComposeResultFailed://发送短信失败
        {
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"抱歉" message:@"短信发送失败" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
            [alert show];
            
        }
            break;
        case MessageComposeResultSent:
        {
        }
            break;
        default:
            break;
    }
}
#endif

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
