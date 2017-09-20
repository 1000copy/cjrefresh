    var nav :  UIViewController?
    import UIKit
    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            nav = Nav()
            //        nav = LangTableViewController(style:.plain)
            nav?.view.backgroundColor = .blue
            self.window!.rootViewController = nav
            self.window?.makeKeyAndVisible()
            return true
        }
    }
    class Nav: UINavigationController {
        var count = 0
        var label : UILabel!
        override func viewDidLoad() {
            super.viewDidLoad()
            self.view.backgroundColor = .white
            self.pushViewController(LangTableViewController(style:.plain), animated: true)
            print(self.navigationBar.bounds)
        }
    }
    class LangTableViewController : RefreshableTVC{
//        let arr = ["swift","obj-c","ruby","swift","obj-c","ruby","swift","obj-c","ruby","swift","obj-c","ruby","swift","obj-c","ruby","swift","obj-c","ruby","swift","obj-c","last"]
        let arr = ["swift","obj-c","ruby","swift"]
        let MyIdentifier = "cell"
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return arr.count
        }
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let a = tableView.dequeueReusableCell(withIdentifier: MyIdentifier)
            a!.textLabel?.text = arr[indexPath.row]
            return a!
        }
        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: MyIdentifier)
        }
    }
    // implements
    enum RefreshState {
        case idle
        case pulling
        case refreshing
    }
    class RefreshHeader : UIView{
        private func addObserver() {
            tableView?.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
        private func removeAbserver() {
            tableView?.removeObserver(self, forKeyPath:"contentSize")
        }
        var curentContentHeight : CGFloat = 0
        var originContentOffsetY : CGFloat? = nil
        override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard tableView.isUserInteractionEnabled else {
                return
            }
            if originContentOffsetY == nil && tableView.contentOffset.y != 0{
                originContentOffsetY = tableView.contentOffset.y
            }
            print(tableView.contentSize.height,tableView.contentOffset.y)
            curentContentHeight = tableView.contentSize.height
            if UIScreen.main.bounds.height > curentContentHeight{
                curentContentHeight = UIScreen.main.bounds.height - tableView.contentInset.top
            }
            self.frame.origin.y = curentContentHeight
        }
        var label : UILabel?
        init(_ tableView : UITableView){
            self.tableView = tableView
            let RefreshHeaderHeight  = 30
            let frame = CGRect(x: 0, y: Int(tableView.contentSize.height), width: Int(UIScreen.main.bounds.width), height: RefreshHeaderHeight)
            super.init(frame: frame)
            state = .idle
            label = UILabel()
            label?.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
            addSubview(label!)
            backgroundColor = UIColor.cyan
            addObserver()
        }
        var text: String?{
            didSet{
                label?.text = text
                makeCenter(label!, self)
            }
        }
        func makeCenter(_ view : UIView, _ parentView : UIView){
            let x = (parentView.frame.width / 2) - (view.frame.width / 2)
            let y = (parentView.frame.height / 2) - (view.frame.height / 2)
            let rect = CGRect(x: x, y: y, width: view.frame.width, height: view.frame.height)
            view.frame = rect
        }
        var tableView : UITableView!
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        var marginTop : CGFloat?
        var state : RefreshState? {
            didSet{
                if state == .idle {
                    text = "idle"
                    if marginTop != nil {
                        tableView.contentInset.bottom = marginTop!
                    }else{
                        marginTop = tableView.contentInset.bottom
                    }
                }else if state == .pulling {
                    text = "pulling"
                }else if state == .refreshing {
                    text = "refreshing"
                    if UIScreen.main.bounds.height < tableView.contentSize.height{
                        tableView.contentInset.bottom +=  (frame.height)
                    }else{
                        tableView.contentInset.bottom +=  (frame.height) + UIScreen.main.bounds.height - tableView.contentSize.height
                    }
                }
            }
        }
    }
    class RefreshableTVC : UITableViewController{
        override init(style: UITableViewStyle) {
            super.init(style:style)
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        // refreshHeader 完整的漏出来了
        let threold = 10
        func isExposed()->Bool{
            print( tableView.contentOffset.y ,refreshHeader.originContentOffsetY!,tableView.contentInset.top , refreshHeader.frame.height,tableView.contentSize.height,UIScreen.main.bounds.height)
    //        return -tableView.contentOffset.y - tableView.contentInset.top > refreshHeader.frame.height
            if  UIScreen.main.bounds.height > tableView.contentSize.height{
                return tableView.contentOffset.y - refreshHeader.originContentOffsetY! > refreshHeader.frame.height
            }else{
                return tableView.contentOffset.y + UIScreen.main.bounds.height > tableView.contentSize.height + refreshHeader.frame.height
            }
        }
        override func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if refreshHeader != nil{
                if refreshHeader?.state == .refreshing{
                    return
                }
                if self.tableView.isDragging{
                    if isExposed() {
                        refreshHeader?.state = .pulling
                    }else{
                        refreshHeader?.state = .idle
                    }
                }else if refreshHeader?.state == .pulling{
                    refreshHeader?.state = .refreshing
                    doRefresh()
                }
            }
        }
        func doRefresh(){
            onRefresh(){
                self.refreshHeader?.state = .idle
            }
        }
        func onRefresh(_ done : (()->Void)?){
            if let done = done {
                delay(3){
                    done()
                }
            }
        }
        var refreshHeader : RefreshHeader!
        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.separatorStyle = .none
            addHeader()
        }
        func addHeader(){
            refreshHeader = RefreshHeader(tableView)
    //        refreshHeader.tableView = self.tableView
            self.tableView.addSubview(refreshHeader)
        }
    }
    func delay(_ s : Double ,_ done :(()->Void)? ){
        let when = DispatchTime.now() + s
        DispatchQueue.main.asyncAfter(deadline: when) {
            done?()
        }
    }
