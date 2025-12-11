//
//  DemoSettingsPanel.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import JXPhotoBrowser

/// JXPhotoBrowser 功能设置面板
class DemoSettingsPanel: UIView {
    
    // MARK: - Public Properties
    
    /// 滚动方向
    var scrollDirection: JXPhotoBrowserScrollDirection = .horizontal {
        didSet {
            scrollDirectionSegmentedControl.selectedSegmentIndex = scrollDirection == .horizontal ? 0 : 1
        }
    }
    
    /// 转场动画类型
    var transitionType: JXPhotoBrowserTransitionType = .zoom {
        didSet {
            let index: Int
            switch transitionType {
            case .fade: index = 0
            case .zoom: index = 1
            case .none: index = 2
            }
            transitionTypeSegmentedControl.selectedSegmentIndex = index
        }
    }
    
    /// 是否启用无限循环滚动
    var isLoopingEnabled: Bool = true {
        didSet {
            loopingSwitch.isOn = isLoopingEnabled
        }
    }
    
    // MARK: - Private Properties
    
    /// 滚动方向标签
    private let scrollDirectionLabel: UILabel = {
        let label = UILabel()
        label.text = "滚动方向"
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 滚动方向选择器
    private let scrollDirectionSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["水平", "垂直"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    /// 转场动画标签
    private let transitionTypeLabel: UILabel = {
        let label = UILabel()
        label.text = "转场动画"
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 转场动画选择器
    private let transitionTypeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["淡入淡出", "缩放", "无"])
        control.selectedSegmentIndex = 1
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
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
    
    /// 屏幕旋转标签
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
        containerView.addSubview(transitionTypeLabel)
        containerView.addSubview(transitionTypeSegmentedControl)
        containerView.addSubview(scrollDirectionLabel)
        containerView.addSubview(scrollDirectionSegmentedControl)
        containerView.addSubview(loopingLabel)
        containerView.addSubview(loopingSwitch)
        
        NSLayoutConstraint.activate([
            // 容器视图
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // 转场动画
            transitionTypeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            transitionTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            transitionTypeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            transitionTypeSegmentedControl.centerYAnchor.constraint(equalTo: transitionTypeLabel.centerYAnchor),
            transitionTypeSegmentedControl.leadingAnchor.constraint(equalTo: transitionTypeLabel.trailingAnchor, constant: 12),
            transitionTypeSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // 滚动方向
            scrollDirectionLabel.topAnchor.constraint(equalTo: transitionTypeLabel.bottomAnchor, constant: 20),
            scrollDirectionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollDirectionLabel.widthAnchor.constraint(equalToConstant: 80),
            
            scrollDirectionSegmentedControl.centerYAnchor.constraint(equalTo: scrollDirectionLabel.centerYAnchor),
            scrollDirectionSegmentedControl.leadingAnchor.constraint(equalTo: scrollDirectionLabel.trailingAnchor, constant: 12),
            scrollDirectionSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // 无限循环
            loopingLabel.topAnchor.constraint(equalTo: scrollDirectionLabel.bottomAnchor, constant: 20),
            loopingLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            loopingLabel.widthAnchor.constraint(equalToConstant: 80),
            loopingSwitch.centerYAnchor.constraint(equalTo: loopingLabel.centerYAnchor),
            loopingSwitch.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            loopingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        scrollDirectionSegmentedControl.addTarget(self, action: #selector(scrollDirectionChanged), for: .valueChanged)
        loopingSwitch.addTarget(self, action: #selector(loopingChanged), for: .valueChanged)
        transitionTypeSegmentedControl.addTarget(self, action: #selector(transitionTypeChanged), for: .valueChanged)
    }
    
    // MARK: - Action Methods
    
    @objc private func scrollDirectionChanged() {
        scrollDirection = scrollDirectionSegmentedControl.selectedSegmentIndex == 0 ? .horizontal : .vertical
    }
    
    @objc private func loopingChanged() {
        isLoopingEnabled = loopingSwitch.isOn
    }
    
    @objc private func transitionTypeChanged() {
        switch transitionTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            transitionType = .fade
        case 1:
            transitionType = .zoom
        case 2:
            transitionType = .none
        default:
            break
        }
    }
}
