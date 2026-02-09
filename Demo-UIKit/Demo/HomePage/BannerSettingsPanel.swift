//
//  BannerSettingsPanel.swift
//  Demo
//
//  控制 Banner 行为的设置面板
//

import UIKit

/// Banner 设置面板
/// 控制 Banner 的无限循环和自动轮播行为，选项变更实时生效
class BannerSettingsPanel: UIView {
    
    // MARK: - Public Properties
    
    /// 是否启用无限循环滚动
    var isLoopingEnabled: Bool = true {
        didSet {
            loopingSwitch.isOn = isLoopingEnabled
            onLoopingChanged?(isLoopingEnabled)
        }
    }
    
    /// 无限循环开关变化回调
    var onLoopingChanged: ((Bool) -> Void)?
    
    /// 是否启用自动轮播
    var isAutoPlayEnabled: Bool = true {
        didSet {
            autoPlaySwitch.isOn = isAutoPlayEnabled
            onAutoPlayChanged?(isAutoPlayEnabled)
        }
    }
    
    /// 自动轮播开关变化回调
    var onAutoPlayChanged: ((Bool) -> Void)?
    
    // MARK: - Private Properties
    
    /// 无限循环标签
    private let loopingLabel: UILabel = {
        let label = UILabel()
        label.text = "无限循环"
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 无限循环开关
    private let loopingSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    /// 自动轮播标签
    private let autoPlayLabel: UILabel = {
        let label = UILabel()
        label.text = "自动轮播"
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 自动轮播开关
    private let autoPlaySwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    /// 容器视图
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(loopingLabel)
        containerView.addSubview(loopingSwitch)
        containerView.addSubview(autoPlayLabel)
        containerView.addSubview(autoPlaySwitch)
        
        NSLayoutConstraint.activate([
            // 容器视图
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // 无限循环
            loopingLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            loopingLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            loopingSwitch.centerYAnchor.constraint(equalTo: loopingLabel.centerYAnchor),
            loopingSwitch.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -16),
            
            // 自动轮播（与无限循环同一行）
            autoPlayLabel.centerYAnchor.constraint(equalTo: loopingLabel.centerYAnchor),
            autoPlayLabel.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 16),
            autoPlaySwitch.centerYAnchor.constraint(equalTo: autoPlayLabel.centerYAnchor),
            autoPlaySwitch.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            loopingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        loopingSwitch.addTarget(self, action: #selector(loopingChanged), for: .valueChanged)
        autoPlaySwitch.addTarget(self, action: #selector(autoPlayChanged), for: .valueChanged)
    }
    
    // MARK: - Action Methods
    
    @objc private func loopingChanged() {
        isLoopingEnabled = loopingSwitch.isOn
    }
    
    @objc private func autoPlayChanged() {
        isAutoPlayEnabled = autoPlaySwitch.isOn
    }
}
