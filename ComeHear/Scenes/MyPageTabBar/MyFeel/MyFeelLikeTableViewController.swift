//
//  MyFeelLikeTableViewController.swift
//  ComeHear
//
//  Created by Pane on 2022/08/01.
//

import UIKit
import Alamofire

class MyFeelLikeTableViewController: UIViewController {
    // MARK: - 변수, 상수
    private var myFeelBoolList = [Bool]()
    private var myFeelShareList = [MyFeelShareDataList]()
    
    //MARK: - 나의 공유한 느낌 UI
    private lazy var mainContentView: UIView = {
        let view = UIView()
        view.backgroundColor = personalColor
        return view
    }()
    
    private lazy var coverView: UIView = {
        let view = UIView()
        view.setupShadow()
        return view
    }()
    
    private lazy var coverPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 \"좋아요\"를 누르신 느낌이 없습니다.\n\n좋아하는 느낌을 추가하기 위해 여행지를 검색해보세요!".localized()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var searchTabButton: UIButton = {
        let button = UIButton()
        button.setupLongButton(title: "관광지 검색하러 가기".localized(), fontSize: 16)
        button.addTarget(self, action: #selector(tapSearchTabButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Woman_Logo_Record_Image")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var tableShadowView: UIView = {
        let view = UIView()
        view.setupShadow()
        view.isHidden = true
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.register(MyFeelSectionTableViewCell.self, forCellReuseIdentifier: "MyFavoriteTableViewSectionCell")
        tableView.register(MyFeelLikeTableViewCell.self, forCellReuseIdentifier: "MyFeelLikeTableViewCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.isHidden = true
        return tableView
    }()
    
    // MARK: - LifeCycle_생명주기
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(indexChanged), name: NSNotification.Name("reportAfterReload"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showToVoice(type: .screenChanged, text: "현재화면은 내가 좋아요한 느낌 화면입니다.")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("reportAfterReload"), object: nil)
    }
}

//MARK: - Extension
extension MyFeelLikeTableViewController {
    
    
    //MARK: - 기본 UI_SETUP
    private func setupNavigation() {
        navigationItem.title = "내가 좋아요 한 느낌".localized()
        navigationController?.setupBasicNavigation()
        
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    private func setupLayout() {
        view.backgroundColor = .white
        view.addSubview(mainContentView)
        
        mainContentView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        [
            coverView, tableShadowView
        ].forEach {
            mainContentView.addSubview($0)
        }
        
        coverView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(intervalSize)
            $0.leading.equalToSuperview().offset(intervalSize)
            $0.trailing.equalToSuperview().inset(intervalSize)
            $0.bottom.equalToSuperview().inset(intervalSize)
        }
        
        [coverPlaceholderLabel, searchTabButton, coverImageView].forEach {
            coverView.addSubview($0)
        }
        
        coverPlaceholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(intervalSize)
            $0.leading.equalToSuperview().offset(intervalSize)
            $0.trailing.equalToSuperview().inset(intervalSize)
        }
        
        searchTabButton.snp.makeConstraints {
            $0.top.equalTo(coverPlaceholderLabel.snp.bottom).offset(intervalSize)
            $0.leading.equalToSuperview().offset(intervalSize)
            $0.trailing.equalToSuperview().inset(intervalSize)
            $0.height.equalTo(40)
        }
        
        coverImageView.snp.makeConstraints {
            $0.top.equalTo(searchTabButton.snp.bottom).offset(intervalSize)
            $0.leading.equalToSuperview().offset(intervalSize)
            $0.trailing.equalToSuperview().inset(intervalSize)
            $0.bottom.equalToSuperview().inset(intervalSize * 2)
            $0.height.equalTo(frameSizeWidth - intervalSize * 2)
        }
        
        tableShadowView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(intervalSize)
            $0.leading.equalToSuperview().offset(intervalSize)
            $0.trailing.equalToSuperview().inset(intervalSize)
            $0.bottom.equalToSuperview().inset(intervalSize)
        }
        
        tableShadowView.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - API Request
    private func requestData() {
        guard let app = UIApplication.shared.delegate as? AppDelegate, app.loginState == .login, let memberIdx = app.userMemberIdx else { return }
        let urlString = feelLikeURL + "?memberIdx=\(memberIdx)"
        
        AF.request(urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
            .responseDecodable(of: MyFeelShareDataModel.self) { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success(let data):
                    self.myFeelShareList = data.myFeelShareList
                    self.myFeelBoolList = Array(repeating: false, count: data.myFeelShareList.count)
                    self.tableView.reloadData()
                    if self.myFeelShareList.count == 0 {
                        self.coverView.isHidden = false
                        self.tableView.isHidden = true
                        self.tableShadowView.isHidden = true
                    } else {
                        self.coverView.isHidden = true
                        self.tableView.isHidden = false
                        self.tableShadowView.isHidden = false
                    }
                case .failure(let error):
                    self.showCloseAlert("죄송합니다.\n서둘러 복구하겠습니다.", "서버점검")
#if DEBUG
                    print(error)
#endif
                }
            }
    }
    
    //MARK: - @objc
    @objc private func tapSearchTabButton() {
        if UIAccessibility.isVoiceOverRunning {
            self.tabBarController?.selectedIndex = 0
        } else {
            self.tabBarController?.selectedIndex = 2
        }
    }
    
    @objc private func indexChanged() {
        requestData()
    }
}

//MARK: - TableView Delegate
extension MyFeelLikeTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if myFeelBoolList[indexPath.section] {
                showToVoice2(type: .announcement, text: "느낌목록접기".localized(with: myFeelShareList[indexPath.section].place))
            } else {
                showToVoice2(type: .announcement, text: "느낌목록펴기".localized(with: myFeelShareList[indexPath.section].place))
            }
            myFeelBoolList[indexPath.section] = !myFeelBoolList[indexPath.section]
            tableView.reloadSections([indexPath.section], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if myFeelBoolList[section] {
            return myFeelShareList[section].list.count + 1
        } else {
            return 1
        }
    }
}

//MARK: - TableView DataSource
extension MyFeelLikeTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return myFeelShareList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return UITableViewCell() }
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyFavoriteTableViewSectionCell") as? MyFeelSectionTableViewCell else { return UITableViewCell() }
            cell.titleLabel.text = "# \(myFeelShareList[indexPath.section].place) ( \(myFeelShareList[indexPath.section].list.count) )"
            if myFeelBoolList[indexPath.section] {
                cell.openButton.setImage(systemName: "chevron.up", pointSize: buttonSize)
                cell.contentView.backgroundColor = moreLightGrayColor
                if app.languageCode == "ko" {
                    cell.accessibilityLabel = "\(myFeelShareList[indexPath.section].place)의 이야기 느낌 \(myFeelShareList[indexPath.section].list.count)개 접기 버튼"
                }
            } else {
                cell.openButton.setImage(systemName: "chevron.down", pointSize: buttonSize)
                cell.contentView.backgroundColor = .white
                if app.languageCode == "ko" {
                    cell.accessibilityLabel = "\(myFeelShareList[indexPath.section].place)의 이야기 느낌 \(myFeelShareList[indexPath.section].list.count)개 펼치기 버튼"
                }
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyFeelLikeTableViewCell") as? MyFeelLikeTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.cellDelegate = self
            cell.feelList = myFeelShareList[indexPath.section].list[indexPath.row-1]
            cell.titleLabel.text = myFeelShareList[indexPath.section].list[indexPath.row-1].title
            cell.indexPath = IndexPath(item: indexPath.row-1, section: indexPath.section)
            if (myFeelShareList[indexPath.section].list[indexPath.row-1].memberLike ?? false) {
                cell.likeButton.setImage(systemName: "heart.fill", pointSize: buttonSize)
                if app.languageCode == "ko" {
                    cell.likeButton.accessibilityLabel = "좋아요를 취소하는"
                }
            } else {
                cell.likeButton.setImage(systemName: "heart", pointSize: buttonSize)
                if app.languageCode == "ko" {
                    cell.likeButton.accessibilityLabel = "좋아요를 누르는"
                }
            }
            return cell
        }
    }
}


// MARK: - Delegate 버튼(듣기, 좋아요, 신고)
extension MyFeelLikeTableViewController: MyFeelLikeTableViewDelegate {
    func feelListenButtonTapped(_ feel: FeelListData) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let topViewController = keyWindow?.visibleViewController else { return }
        if app.loginState == .logout {
            let loginAction = UIAlertAction(title: "네".localized(), style: UIAlertAction.Style.default) { _ in
                let loginViewContrller = LoginViewController()
                guard let topViewController = keyWindow?.visibleViewController else { return }
                topViewController.navigationController?.pushViewController(loginViewContrller, animated: true)
            }
            topViewController.showTwoActionAlert("로그인이 필요합니다.\n로그인페이지로 이동하시겠습니까?", "로그인", loginAction)
        } else {
            LoadingIndicator.showLoading(className: self.className, function: "feelListenButtonTapped")
            let playViewController = FeelPlayViewController()
            playViewController.selectFeel = feel
            playViewController.feelTitleView.text = "재생화면".localized() + " - \(feel.title)"
            playViewController.writer.text = "\(feel.regMemberNickname ?? "") " + "님의 느낌".localized()
            playViewController.audioURL = feel.audioUrl
            
            DispatchQueue.background(
                background: {
                    playViewController.setupAVAudioPlayer()
                },
                completion: {
                    playViewController.hero.isEnabled = true
                    playViewController.hero.modalAnimationType = .fade
                    playViewController.modalPresentationStyle = UIAccessibility.isVoiceOverRunning ? .fullScreen : .overFullScreen
                    guard let topViewController = keyWindow?.visibleViewController else { return }
                    topViewController.present(playViewController, animated: true, completion: nil)
                }
            )
        }
    }
    
    func feelLikeButtonTapped(_ indexPath: IndexPath, _ tableIndex: Int?) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let topViewController = keyWindow?.visibleViewController else { return }
        if app.loginState == .logout {
            let loginAction = UIAlertAction(title: "네".localized(), style: UIAlertAction.Style.default) { _ in
                let loginViewContrller = LoginViewController()
                topViewController.navigationController?.pushViewController(loginViewContrller, animated: true)
            }
            topViewController.showTwoActionAlert("로그인이 필요합니다.\n로그인페이지로 이동하시겠습니까?", "로그인", loginAction)
        } else {
            guard let memberIdx = app.userMemberIdx else { return }
            let feel = myFeelShareList[indexPath.section].list[indexPath.row]
            var request = URLRequest(url: URL(string: feelLikeURL)!)
            request.httpMethod = (feel.memberLike ?? false) ? "DELETE" : "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            
            let params = [
                "likeMemberIdx": memberIdx,
                "regMemberIdx": feel.regMemberIdx ?? 0,
                "stid" : feel.stid,
                "stlid" : feel.stlid,
                "title" : feel.title
            ] as [String : Any]
            
            do {
                try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
            } catch {
#if DEBUG
                    print("http Body Error")
#endif
            }
            
            LoadingIndicator.showLoading(className: self.className, function: "feelLikeButtonTapped")
            AF.request(request).responseDecodable(of: BasicResponseModel.self) { [weak self] (response) in
                guard let self = self else { return }
                switch response.result {
                case .success(let data):

                    if data.status == 201 {
                        self.myFeelShareList[indexPath.section].list[indexPath.row].memberLike = !(self.myFeelShareList[indexPath.section].list[indexPath.row].memberLike ?? false)
                        self.showToast(message: "'좋아요'를 눌렀습니다.", font: .systemFont(ofSize: 16), vcBool: true)
                        self.showToVoice(type: .announcement, text: "좋아요를 눌렀습니다.")
                        self.tableView.reloadData()
                    } else if data.status == 204{
                        self.myFeelShareList[indexPath.section].list[indexPath.row].memberLike = !(self.myFeelShareList[indexPath.section].list[indexPath.row].memberLike ?? false)
                        topViewController.showToast(message: "'좋아요'를 취소하였습니다.", font: .systemFont(ofSize: 16), vcBool: true)
                        self.showToVoice(type: .announcement, text: "좋아요를 취소하였습니다.")
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    guard let topViewController = keyWindow?.visibleViewController else { return }
                    topViewController.showCloseAlert("죄송합니다.\n서둘러 복구하겠습니다.", "서버점검")
#if DEBUG
print("🚫 Alamofire Request Error\nCode:\(error._code), Message: \(error.errorDescription!)")
#endif
                }
                DispatchQueue.main.async {
                    LoadingIndicator.hideLoading()
                }
            }
        }
    }
    
    func feelReportTapped(_ feel: FeelListData) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let topViewController = keyWindow?.visibleViewController else { return }
        if app.loginState == .logout {
            let loginAction = UIAlertAction(title: "네".localized(), style: UIAlertAction.Style.default) { _ in
                let loginViewContrller = LoginViewController()
                guard let topViewController = keyWindow?.visibleViewController else { return }
                topViewController.navigationController?.pushViewController(loginViewContrller, animated: true)
            }
            topViewController.showTwoActionAlert("로그인이 필요합니다.\n로그인페이지로 이동하시겠습니까?", "로그인", loginAction)
        } else {
            let feelReportViewController = FeelReportViewController(selectFeel: feel)
            feelReportViewController.hero.isEnabled = true
            feelReportViewController.hero.modalAnimationType = .fade
            feelReportViewController.modalPresentationStyle = UIAccessibility.isVoiceOverRunning ? .fullScreen : .overFullScreen
            present(feelReportViewController, animated: true)
        }
    }
}
