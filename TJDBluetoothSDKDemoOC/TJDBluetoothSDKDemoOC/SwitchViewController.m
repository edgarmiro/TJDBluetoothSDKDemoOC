//
//  SwitchViewController.m
//  TJDBluetoothSDKDemoOC
//
//  Created by tjd on 2019/1/8.
//  Copyright © 2019年 tjd. All rights reserved.
//

#import "SwitchViewController.h"

@interface SwitchViewController () <UITableViewDelegate, UITableViewDataSource, WristbandSetDelegate> {
    NSArray *titleArray_;
}
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) FunctionSwitchModel *myModel;

@end

@implementation SwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNotify];
    titleArray_ = @[@"Levanta la mano para iluminar", @"Recordatorio sedentario", @"Recordatorio de agua potable", @"Sacude una foto", @"Inteligente anti-perdida"];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    [self.view addSubview:_table];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    bleSelf.wristbandDelegate = self;
    [bleSelf getSwitchForWristband];
}

- (void)didSetWristbandWithSwitch:(BOOL)isSuccess {
    if (isSuccess) {
        NSLog(@"Modificar la configuración del interruptor con éxito");
    }
    else {
        NSLog(@"Modificación de la configuración del interruptor fallida");
    }
}

- (void)setupNotify {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.setOrRead_Switch object:nil];
}


- (void)handleNotify:(NSNotification *)notify {
    if (notify.name == WristbandNotifyKeys.setOrRead_Switch) {
        NSLog(@"Se completó la configuración del interruptor de lectura");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.table reloadData];
        });
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    UISwitch *switchBtn = [[UISwitch alloc] init];
    switchBtn.tag = indexPath.row;
    [switchBtn addTarget:self action:@selector(pressSwitchBtn:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchBtn;
    
    if (indexPath.row == 0) {
        switchBtn.on = bleSelf.functionSwitchModel.isLightScreen;
    }
    
    if (indexPath.row == 1) {
        switchBtn.on = bleSelf.functionSwitchModel.isLongSit;
    }
    
    if (indexPath.row == 2) {
        switchBtn.on = bleSelf.functionSwitchModel.isDrink;
    }
    
    if (indexPath.row == 3) {
        switchBtn.on = bleSelf.functionSwitchModel.isTakePhoto;
    }
    
    if (indexPath.row == 4) {
        switchBtn.on = bleSelf.functionSwitchModel.isAntiLost;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (void)pressSwitchBtn:(UISwitch *)sender {
    NSLog(@"%s", __func__);
    if (sender.tag == 0) {
        bleSelf.functionSwitchModel.isLightScreen = sender.on;
    }
    
    if (sender.tag == 1) {
        bleSelf.functionSwitchModel.isLongSit = sender.on;
    }
    
    if (sender.tag == 2) {
        bleSelf.functionSwitchModel.isDrink = sender.on;
    }
    
    if (sender.tag == 3) {
        bleSelf.functionSwitchModel.isTakePhoto = sender.on;
    }
    
    if (sender.tag == 4) {
        bleSelf.functionSwitchModel.isAntiLost = sender.on;
    }
    NSLog(@"isConnected %d", bleSelf.isConnected);
    if (bleSelf.isConnected) {
        [bleSelf setSwitchForWristband:bleSelf.functionSwitchModel];
        // Guardar información después de la modificación
        [FunctionSwitchModel setModel:bleSelf.functionSwitchModel];
        [_table reloadData];
    }
    [WUAppManager testPrint:bleSelf.functionSwitchModel];
}

@end
