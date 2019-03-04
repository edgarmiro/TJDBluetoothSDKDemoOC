//
//  FunctionViewController.m
//  TJDBluetoothSDKDemoOC
//
//  Created by tjd on 2019/1/8.
//  Copyright © 2019年 tjd. All rights reserved.
//

#import "FunctionViewController.h"
#import "SwitchViewController.h"

@interface FunctionViewController () <UITableViewDelegate, UITableViewDataSource, WristbandSetDelegate> {
    NSArray *titleArray_;
}
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray<SleepModel *> * dataArray;
@property (nonatomic, strong) HeartModel *heartModel;
@property (nonatomic, strong) BloodModel *bloodModel;

@end

@implementation FunctionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNotify];
    titleArray_ = @[@"Interruptor de función relacionado con el dispositivo", @"Medición de la frecuencia cardíaca (medición de clic)", @"Medición de la presión arterial (haga clic en la medición)", @"Modificar información del usuario"];
    
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    bleSelf.wristbandDelegate = self;
}

- (void)didSetWristbandWithUserinfo:(BOOL)isSuccess {
    if (isSuccess) {
        NSLog(@"Modificar la información del usuario correctamente");
    }
    else {
        NSLog(@"Error al modificar la información del usuario");
    }
}

- (void)setupNotify {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.devSendCeLiang_heart object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.devSendCeLiang_blood object:nil];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleNotify:(NSNotification *)notify {
    
    // Medición de la frecuencia cardíaca, envío de datos en tiempo real.
    if (notify.name == WristbandNotifyKeys.devSendCeLiang_heart) {
        HeartModel *model = notify.object;
        _heartModel = model;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.table reloadData];
        });
    }
    
    // Medición de la presión arterial, envío de datos en tiempo real.
    if (notify.name == WristbandNotifyKeys.devSendCeLiang_blood) {
        BloodModel *model = notify.object;
        _bloodModel = model;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.table reloadData];
        });
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return titleArray_.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.text = titleArray_[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (indexPath.row == 0 || indexPath.row == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 1) {
        cell.detailTextLabel.text = @(_heartModel.heart).stringValue;
    }
    
    if (indexPath.row == 2) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/%d", (int)_bloodModel.max, (int)_bloodModel.min];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if (indexPath.row == 0) {
        SwitchViewController *vc = [[SwitchViewController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
    }
    
    if (indexPath.row == 1) {
        self.title = @"Medición de la frecuencia cardíaca";
        [bleSelf startMeasure:WristbandMeasureType.heart];
    }
    
    if (indexPath.row == 2) {
        self.title = @"Medir la presión arterial";
        [bleSelf startMeasure:WristbandMeasureType.blood];
    }
    
    if (indexPath.row == 3) {
        // La depuración se utiliza para ver información, que es independiente de la función
        [WUAppManager testPrint:bleSelf.userInfo];
        WUUserInfo *model = bleSelf.userInfo;
        model.sex = 1;
        // Modifique la información del usuario y envíela al dispositivo Bluetooth
        [bleSelf setUserinfoForWristband:model];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

@end
