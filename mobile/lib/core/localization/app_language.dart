/// Application language catalogue.
///
/// `zh_HK` is Traditional Chinese using wording natural for Cantonese-speaking
/// Hong Kong users. Keep the English text as the key so legacy UI text can be
/// translated gradually without leaking language checks into every screen.
class AppLanguage {
  static const english = 'en';
  static const cantonese = 'zh_HK';

  static String translate(String value, String languageCode) {
    if (languageCode != cantonese) return value;

    final direct = _cantonese[value];
    if (direct != null) return direct;

    // Dynamic labels used across dashboards and leave workflows.
    if (value.startsWith('Good morning,')) {
      return value.replaceFirst('Good morning,', '早晨，');
    }
    if (value.startsWith('Good afternoon,')) {
      return value.replaceFirst('Good afternoon,', '午安，');
    }
    if (value.startsWith('Good evening,')) {
      return value.replaceFirst('Good evening,', '晚上好，');
    }
    if (value.startsWith('Welcome back,')) {
      return value.replaceFirst('Welcome back,', '歡迎返嚟，');
    }
    if (value.startsWith('Error:')) {
      return value.replaceFirst('Error:', '錯誤：');
    }
    if (value.startsWith('Failed:')) {
      return value.replaceFirst('Failed:', '失敗：');
    }
    if (value.startsWith('Level ')) {
      return value.replaceFirst('Level ', '第 ').replaceFirst(' — ', '級：');
    }
    if (value.startsWith('Applicant: ')) {
      return value
          .replaceFirst('Applicant: ', '申請人：')
          .replaceFirst('\nType: ', '\n類別：');
    }
    if (value.startsWith('Reason: ')) {
      return value.replaceFirst('Reason: ', '原因：');
    }
    if (value.startsWith('Status: ')) {
      return value.replaceFirst('Status: ', '狀態：');
    }
    if (RegExp(r'^\d+ days? requested$').hasMatch(value)) {
      return value.replaceFirst(RegExp(r' requested$'), '日已申請');
    }
    if (RegExp(r'^\d+ days? left$').hasMatch(value)) {
      return value.replaceFirst(RegExp(r' days? left$'), '日剩餘');
    }
    if (RegExp(r'^\d+ used of \d+$').hasMatch(value)) {
      final parts = value.split(' used of ');
      return '已使用 ${parts[0]}／${parts[1]} 日';
    }
    return value;
  }

  static const Map<String, String> _cantonese = {
    'Food Angel': '惜食堂',
    'HR Staff Portal': '人力資源員工平台',
    'Food Angel Staff Portal': '惜食堂員工平台',
    'Food Angel Smart HR Tool': '惜食堂智能人力資源工具',
    'Welcome back': '歡迎返嚟',
    'Sign in to access your portal': '登入以使用你嘅平台',
    'Email Address': '電郵地址',
    'Password': '密碼',
    'Sign In': '登入',
    'Sign Out': '登出',
    'Login failed': '登入失敗',
    'Please enter your email': '請輸入電郵地址',
    'Enter a valid email': '請輸入有效嘅電郵地址',
    'Please enter your password': '請輸入密碼',
    'DEMO CREDENTIALS': '示範帳戶',
    'Dashboard': '主頁',
    'Home': '首頁',
    'Attendance': '出勤',
    'Attendance History': '出勤紀錄',
    'Team Attendance': '團隊出勤',
    'Leave': '請假',
    'Leaves': '假期',
    'Leave Requests': '請假申請',
    'Leave Details': '請假詳情',
    'Leave Approvals': '假期審批',
    'Leave Management Console': '假期管理中心',
    'Request Leave': '申請假期',
    'Submit Leave Request': '提交請假申請',
    'Leave request submitted!': '請假申請已提交！',
    'Leave request cancelled': '請假申請已取消',
    'Leave request not found': '搵唔到請假申請',
    'No leave requests found': '暫時冇請假申請',
    'No attendance records': '暫時冇出勤紀錄',
    'Staff': '員工',
    'Staff Directory': '員工名錄',
    'Profile': '個人資料',
    'My Profile': '我嘅個人資料',
    'Team': '團隊',
    'Messages': '訊息',
    'Tasks': '工作',
    'Language': '語言',
    'English': 'English',
    'Cantonese (Traditional Chinese)': '廣東話（繁體中文）',
    'Save': '儲存',
    'Saving...': '儲存中…',
    'Save Profile Changes': '儲存個人資料更改',
    'Cancel': '取消',
    'Close': '關閉',
    'No': '否',
    'Yes, Cancel': '係，取消申請',
    'Confirm': '確認',
    'Reject': '拒絕',
    'Review': '審核',
    'Details': '詳情',
    'View All': '查看全部',
    'Manage →': '管理 →',
    'Approve L1': '第一級批准',
    'Approve L2': '第二級批准',
    'Approve (L1)': '批准（第一級）',
    'Grant Final (L2)': '最終批准（第二級）',
    'Final Approve (L2)': '最終批准（第二級）',
    'Grant Final Approval': '給予最終批准',
    'Confirm L1 Approval': '確認第一級批准',
    'Confirm Rejection': '確認拒絕',
    'Approve Leave (L1)': '批准假期（第一級）',
    'Reject Leave Request': '拒絕請假申請',
    'Leave request approved': '請假申請已批准',
    'Leave request rejected': '請假申請已拒絕',
    'Leave fully approved (L2 Approved)': '假期已獲最終批准（第二級）',
    'Leave request approved (L1 Approved)': '請假申請已獲第一級批准',
    'Cancel Leave Request?': '取消請假申請？',
    'Are you sure you want to cancel this leave request?': '你確定要取消呢個請假申請嗎？',
    'Are you sure you want to sign out from Food Angel Staff Portal?':
        '你確定要登出惜食堂員工平台嗎？',
    'Profile updated successfully': '個人資料已成功更新',
    'Failed to update:': '更新失敗：',
    'Primary Location': '主要工作地點',
    'Department': '部門',
    'Position': '職位',
    'Join Date': '入職日期',
    'Contact Phone': '聯絡電話',
    'Not provided': '未提供',
    'Password & Security': '密碼及安全',
    'Default credentials: 1234 or admin': '預設密碼：1234 或 admin',
    'Password changes are managed by HR Admin.': '密碼更改由人力資源管理員處理。',
    'Notifications': '通知',
    'Push alerts for approvals & reminders': '審批及提醒推送通知',
    'App Mini Tour': '應用程式導覽',
    'Replay guided tour of portal features': '重新觀看平台功能導覽',
    'Start Date': '開始日期',
    'End Date': '結束日期',
    'Please select start and end dates': '請選擇開始及結束日期',
    'Retrospective (after the fact)': '補交申請（事後）',
    'Approval Chain': '審批流程',
    'Timeline': '時間線',
    'Days Worked': '工作日數',
    'Late Days': '遲到日數',
    'Missing Out': '未打卡下班',
    'this month': '本月',
    'Pending Approvals': '待審批項目',
    'Team Present': '團隊已出勤',
    'L2 Final Approvals': '第二級最終審批',
    'Annual': '年假',
    'Sick': '病假',
    'Personal': '事假',
    'ANNUAL': '年假',
    'SICK': '病假',
    'PERSONAL': '事假',
    'PENDING': '待審批',
    'L1 APPROVED': '第一級已批准',
    'L1_APPROVED': '第一級已批准',
    'FULLY APPROVED': '已最終批准',
    'FULLY_APPROVED': '已最終批准',
    'APPROVED': '已批准',
    'REJECTED': '已拒絕',
    'CANCELLED': '已取消',
    'ON TIME': '準時',
    'ON_TIME': '準時',
    'LATE': '遲到',
    'Present': '已出勤',
    'Absent': '缺勤',
    'On Leave': '休假中',
    'Select Date': '選擇日期',
    'Refresh': '重新整理',
    'Search staff by name, ID or site...': '按姓名、員工編號或地點搜尋…',
    'Add remark for this decision': '為呢個決定加入備註',
    'Add HR notes or conditions': '加入人力資源備註或條件',
    'Add additional notes or reason...': '加入其他備註或原因…',
    'Welcome to Food Angel': '歡迎使用惜食堂',
    'Your all-in-one Smart HR mobile tool for daily shifts, real-time attendance, and seamless leave requests.':
        '你嘅一站式智能人力資源手機工具，處理每日更次、即時出勤及請假申請。',
    'How to Check In (Start Shift)': '點樣上班打卡',
    'When you arrive at your workstation or hub, open the Home dashboard and tap "Clock In" to begin your workday.':
        '到達工作崗位或中心後，打開首頁並撳「上班打卡」開始工作。',
    'How to Clock Out (End Shift)': '點樣下班打卡',
    'When your workday is completed, tap "Clock Out" to save your total worked hours and prevent missing punch logs.':
        '完成工作後，撳「下班打卡」儲存總工作時數，避免漏咗打卡紀錄。',
    'How to Submit a Leave Request': '點樣提交請假申請',
    'Need time off? Check your live leave balance and submit your request in seconds for quick supervisor approval.':
        '想請假？查看即時假期餘額，幾秒鐘就可以提交申請畀主管審批。',
    'Attendance Records & History': '出勤紀錄及歷史',
    'Review all your shift timestamps, monthly hours worked, and attendance consistency in the Attendance tab.':
        '喺「出勤」分頁查看所有更次時間、每月工作時數及出勤紀錄。',
    'Profile, Help & Ready to Go!': '個人資料、幫助及準備就緒！',
    'Update your personal contact details, get approval notifications, and replay this tour whenever you need a refresher.':
        '更新個人聯絡資料、接收審批通知，隨時重新觀看本導覽。',
    'Staff Quick Tour & Guide': '員工快速導覽',
    'Verified': '已驗證',
    'WELCOME ABOARD': '歡迎使用',
    'STEP 1 • CLOCK IN': '第一步 • 上班打卡',
    'STEP 2 • CLOCK OUT': '第二步 • 下班打卡',
    'STEP 3 • LEAVE REQUEST': '第三步 • 請假申請',
    'STEP 4 • ATTENDANCE': '第四步 • 出勤',
    'STEP 5 • PROFILE & HELP': '第五步 • 個人資料及幫助',
    'Currently Working': '工作進行中',
    'Not Checked In': '未上班打卡',
    'Checked In! (Tap to reset)': '已上班打卡！（撳一下重設）',
    'Tap to Clock In': '撳一下上班打卡',
    'Clock In': '上班打卡',
    'Clock Out': '下班打卡',
    'Work Complete 🎉': '工作完成 🎉',
    'Shift In Progress': '更次進行中',
    'Undo': '復原',
    'Active 08:30 → Now': '08:30 至而家進行中',
    '8h 15m Worked': '已工作 8 小時 15 分',
    'Annual Leave': '年假',
    'Annual Leave • 2 Days (Nov 3 - 4)': '年假 • 2 日（11月3至4日）',
    'Pending': '待審批',
    'Approved': '已批准',
    'Rejected': '已拒絕',
    'Cancelled': '已取消',
    'Leave Type': '假期類別',
    'Dates': '日期',
    'Select': '選擇',
    'Reason (Optional)': '原因（可選）',
    'Doctor note / supporting document required': '需要醫生證明／證明文件',
    'Leave already taken, adding record now': '假期已經放咗，依家補回紀錄',
    'Please select leave type': '請選擇假期類別',
    'Duration': '日數',
    'Type': '類別',
    'Employee': '員工',
    'Location': '工作地點',
    'Phone': '電話',
    'Work Information': '工作資料',
    'Operations': '營運部',
    'Operations Hub': '營運中心',
    'General Staff': '一般員工',
    'Site Supervisor': '地點主管',
    'HR Admin': '人力資源管理員',
    'HR Administrator': '人力資源管理員',
    'Supervisor': '主管',
    'Staff Member': '員工',
    'Quick Actions': '快速功能',
    'Request\nLeave': '申請\n假期',
    'My\nLeaves': '我嘅\n假期',
    'Attendance\nHistory': '出勤\n紀錄',
    'My\nProfile': '我嘅\n資料',
    'Leave Balance': '假期餘額',
    'Recent Activity': '最近動態',
    'This Month': '本月',
    'Last Updated': '最後更新',
    'Days Present': '出勤日數',
    'Days Absent': '缺勤日數',
    'Hours': '工時',
    'Late': '遲到',
    'All': '全部',
    'All Records': '全部紀錄',
    'All Pending': '全部待審批',
    'No attendance records found for this date': '當日冇出勤紀錄',
    'No leave requests in this category': '呢個類別暫時冇請假申請',
    'No requests in this category': '呢個類別暫時冇申請',
    'No pending leave requests requiring your review': '暫時冇需要你審核嘅請假申請',
    'No pending L2 approvals': '暫時冇待第二級審批項目',
    'No staff found matching query': '搵唔到符合搜尋條件嘅員工',
    'Awaiting L2': '等待第二級審批',
    'Awaiting HR L2 Approval': '等待人力資源第二級審批',
    'Supervisor Approved — Awaiting HR': '主管已批准 — 等待人力資源審批',
    'Supervisor Approved': '主管已批准',
    'Rejected by HR Admin': '被人力資源管理員拒絕',
    'Rejected by supervisor': '被主管拒絕',
    'Requires Your Approval (L1)': '需要你第一級審批',
    'Review Leaves': '審核假期',
    'Supervisor Actions': '主管功能',
    'Management Consoles': '管理中心',
    'Leave Console': '假期管理',
    'HR Operations Portal': '人力資源營運平台',
    'All caught up!': '全部已處理！',
    'All leaves endorsed by supervisors are processed': '所有主管已批核嘅假期均已處理',
    'Announcements': '公告',
    'Payslips': '糧單',
    'Payslip Generated': '糧單已生成',
    'Team Meeting': '團隊會議',
    'Get Started!': '開始使用！',
    'Next Step': '下一步',
    'Back': '返回',
    'Skip Tour': '略過導覽',
    'Full Name': '全名',
    'Edit Profile': '編輯個人資料',
    'Notes / Comments (Optional)': '備註／意見（可選）',
    'HR Remarks (Optional)': '人力資源備註（可選）',
    'Food Angel Smart HR Tool • v1.0.0 (Build 2026)':
        '惜食堂智能人力資源工具 • v1.0.0（2026版本）',
    '© 2026 Food Angel · HR Attendance & Reconciliation':
        '© 2026 惜食堂 · 人力資源出勤及核對',
    '⚡ 1-Tap Attendance Check-In & Clock-Out': '⚡ 一撳即上／下班打卡',
    '📋 Real-Time Leave Balances & Fast Submissions': '📋 即時假期餘額及快速提交',
    '📊 Monthly Timesheets & Worked Hours Tracking': '📊 每月工時表及工作時數追蹤',
    '🟢 1-Tap Clock In: Tap the white "Clock In" button on your Home card.':
        '🟢 一撳上班打卡：喺首頁卡片撳白色「上班打卡」按鈕。',
    '⏱️ Automatic Live Timer: Your shift elapsed time starts immediately.':
        '⏱️ 自動即時計時：更次時間會即時開始計算。',
    '📍 Hub Verification: Automatically logs your workstation & arrival time.':
        '📍 中心驗證：自動記錄工作地點及到達時間。',
    '🔴 Tap Clock Out: Available right on the check-in card while shift is active.':
        '🔴 撳下班打卡：更次進行中時可喺打卡卡片直接使用。',
    '🎉 Instant Shift Summary: Calculates exact hours worked and overtime.':
        '🎉 即時更次摘要：計算準確工作時數及加班時間。',
    '⚠️ Avoid Missing Out: Always clock out daily to keep your timesheet verified.':
        '⚠️ 避免漏打下班卡：每日記得下班打卡，保持工時表正確。',
    '🏖️ Check Balances: See remaining Annual, Sick, and Personal quotas.':
        '🏖️ 查看餘額：查看年假、病假及事假剩餘額。',
    '📝 Fast Submission: Tap "Request Leave" on Home or open the Leave tab.':
        '📝 快速提交：喺首頁撳「申請假期」，或者打開「請假」分頁。',
    '⏳ Track Status: Live status badges: Pending, Approved, or Rejected.':
        '⏳ 追蹤狀態：即時顯示待審批、已批准或已拒絕。',
    '📅 Calendar Breakdown: Color-coded days worked and verified logs.':
        '📅 日曆摘要：以顏色顯示工作日及已驗證紀錄。',
    '⏱️ Computed Shift Hours: View daily totals, on-time arrivals & overtime.':
        '⏱️ 計算更次工時：查看每日總數、準時到達及加班。',
    '🔍 Self-Verification: Spot any missing clock-outs and resolve with supervisor.':
        '🔍 自我核對：發現漏打下班卡後可向主管處理。',
    '👤 Profile & Contacts: Update phone number and emergency contacts.':
        '👤 個人資料及聯絡方式：更新電話及緊急聯絡人。',
    '🔔 Push Notifications: Stay updated when leaves are approved by supervisor.':
        '🔔 推送通知：主管批准假期後即時收到通知。',
    '🧭 Replay Tour Anytime: Tap the top bar 🧭 icon or visit Profile > App Mini Tour.':
        '🧭 隨時重看導覽：撳頂部 🧭 圖示，或前往個人資料 > 應用程式導覽。',

    // ── Check-in / Check-out (Barcode Page) ──
    'Check In / Out': '上下班打卡',
    'Scan to Check In': '掃描上班打卡',
    'Scan to Check Out': '掃描下班打卡',
    'Scan Check-In QR Code': '掃描上班打卡二維碼',
    'Scan Check-Out QR Code': '掃描下班打卡二維碼',
    'Ready to Check In': '準備上班打卡',
    'Ready to Check Out': '準備下班打卡',
    'Scan the QR code at your workstation to clock out and save your worked hours.':
        '喺工作崗位掃描二維碼以打下班卡並儲存工作時數。',
    'Scan the QR code at your workstation or Food Angel hub to begin your shift.':
        '喺工作崗位或惜食堂中心掃描二維碼以開始更次。',
    'Location will be verified automatically': '地點將自動驗證',
    'Point at the Food Angel QR Code': '對準惜食堂二維碼',
    'Scan to end your shift': '掃描以結束更次',
    'Location is being verified': '正在驗證地點',
    'Invalid QR code. Please scan a valid Food Angel location QR.':
        '無效二維碼，請掃描有效嘅惜食堂地點二維碼。',
    '✓ Checked in at': '✓ 已於',
    'Checked out!': '已下班打卡！',
    'Worked': '工作咗',
    'Great Work Today!': '今日做得好！',
    'You worked': '你今日工作咗',
    'today': '。',
    'Your attendance has been recorded. See you tomorrow!':
        '出勤紀錄已儲存，明天見！',
    'IN': '上班',
    'OUT': '下班',
    'Hours Worked': '工作時數',

    // ── Location Permissions ──
    'Location Required': '需要地點權限',
    'Please turn on Location Services to check in.':
        '請開啟位置服務以進行打卡。',
    'Location Permission Denied': '地點權限被拒絕',
    'Location access is needed to verify your workplace. Please grant it in Settings.':
        '需要地點存取權限以驗證工作地點，請在設定中授權。',
    'Location Permission Blocked': '地點權限已被封鎖',
    'Location permission is permanently denied. Please enable it in your device Settings.':
        '地點權限已被永久拒絕，請在裝置設定中啟用。',
    'Open Settings': '開啟設定',

    // ── HR Register Staff ──
    'Register New Staff': '登記新員工',
    'New Staff Account': '新員工帳戶',
    'Fill in the details to create a login credential':
        '填寫資料以建立登入帳戶',
    'Personal Information': '個人資料',
    'Login Credentials': '登入資料',
    'Register Staff': '登記員工',
    'Staff Type': '員工類別',
    'Role': '職務',
    'Name is required': '必須填寫姓名',
    'Email is required': '必須填寫電郵',
    'Email already exists': '電郵已存在',
    'Min 4 characters': '最少4個字元',
    'Password must be at least 4 characters': '密碼必須至少4個字元',
    'Create Staff Account': '建立員工帳戶',
    'Creating Account...': '建立帳戶中…',
    'Staff Registered!': '員工已登記！',
    'The account has been created. Share credentials securely.':
        '帳戶已建立，請以安全方式分享登入資料。',
    'Please share login credentials privately and ask staff to keep them secure.':
        '請以私下方式分享登入資料，並提醒員工妥善保管。',
    'Done': '完成',
    'Error': '錯誤',
    'Manage': '管理',

    // ── Supervisor & HR Mini Tours ──
    'Welcome, Supervisor!': '歡迎，主管！',
    'Supervisors do NOT check in or check out. Your role is leading your team, approving leaves, and monitoring shift coverage across stations.':
        '主管無需上下班打卡。你嘅主要職責係領導團隊、審批請假申請及監控各站點嘅更次出勤。',
    '🛡️ No Punch Needed: Supervisors manage shifts without checking in/out.':
        '🛡️ 無需打卡：主管專注管理更次，無需打卡。',
    '📋 Level 1 Leave Approvals: Verify and approve staff leave requests.':
        '📋 第一級請假審批：核對及批准員工請假申請。',
    '👥 Live Team Roster: Real-time oversight across your assigned stations.':
        '👥 即時團隊名單：即時監控所屬站點出勤情況。',
    'Supervisor Operations Hub': '主管營運中心',
    'Shift Management & Approvals': '更次管理及審批',
    'No Punch Req.': '無需打卡',
    'How to Approve Leave Requests': '點樣審批員工請假申請',
    'When team members apply for sick, annual, or emergency leave, you conduct Level 1 review and approval.':
        '當隊員申請病假、年假或事假時，你負責進行第一級審批。',
    '⚡ 1-Tap Quick Approve: Tap "Approve" directly on pending leave cards.':
        '⚡ 一撳快速審批：喺待審批卡片直接撳「批准」。',
    '🔍 Inspect Reason & Proof: View reason, dates, and medical certificates.':
        '🔍 檢查原因及證明：查看請假原因、日期及醫生證明書。',
    '⏩ Escalates to HR: L1 approved requests automatically advance to HR.':
        '⏩ 自動呈交人力資源：第一級批准後會自動交由人力資源審批。',
    'Live Team Attendance & Coverage': '即時團隊出勤及更次',
    'Monitor who has scanned in at your assigned workstations (Sham Shui Po, Kwai Chung, etc.) in real time without roll calls.':
        '即時掌握所屬站點（深水埗、葵涌等）嘅掃描出勤情況，免除點名。',
    '🟢 Real-Time Presence: See who is on site and who hasn\'t scanned in yet.':
        '🟢 即時出勤：清楚了解邊個已到崗位、邊個仲未掃描打卡。',
    '⏱️ Shift Hours: Inspect exact clock-in times and accumulated hours.':
        '⏱️ 更次工時：查看準確打卡時間及已累積工時。',
    '📍 Station Filter: Switch between your assigned warehouses and hubs.':
        '📍 站點篩選：喺你負責嘅不同中心及工場之間切換。',
    'What You Can Do as Supervisor': '主管功能總覽',
    'Quick overview of your supervisor tools across bottom navigation tabs.':
        '底部導航欄主管功能一覽。',
    'Welcome to HR Administration': '歡迎使用人力資源管理中心',
    'As HR Administrator, you oversee the entire organization: registering new staff, setting up office credentials, and issuing final leave approvals.':
        '作為人力資源管理員，你負責管理全體員工：登記新員工、設定辦公室登入資料及最終審批請假。',
    '👥 Register New Staff & Assign Office Credentials Instantly':
        '👥 即時登記新員工並分配辦公室登入帳號',
    '⚖️ Level 2 (Final) Leave Authorizations & Company Policies':
        '⚖️ 第二級（最終）請假簽批及公司政策把關',
    '📈 Organization-Wide Workforce Directory & Audit Records':
        '📈 全機構員工名冊及出勤審核紀錄',
    'HR Central Administration': '人力資源核心管理',
    'All-Staff Operations & Policies': '全體員工營運及政策',
    'Full Access': '全權限',
    'Register Staff & Office Credentials': '登記員工帳號及辦公室資料',
    'Easily create employee accounts, assign them to a physical workstation or office, and grant credentials they can immediately use to log in.':
        '輕鬆建立員工帳戶、指定工作站點或辦公室，並提供可即時登入嘅憑證。',
    '🏢 Office & Station: Assign Sham Shui Po, Kwai Chung, Sha Tin, etc.':
        '🏢 辦公室及站點：分配深水埗、葵涌、沙田等。',
    '🔑 Instant Login Credentials: Password works right away upon registration.':
        '🔑 即時登入憑證：登記後密碼即可立即登入。',
    '📝 Staff Categories: Support Full-Time, Part-Time, and Volunteers.':
        '📝 員工類別：支援全職、兼職及義工。',
    'Level 2 (Final) Leave Authorization': '第二級（最終）請假審批',
    'Review leaves pre-approved by supervisors and issue final authorization for payroll and quota deduction.':
        '審核主管已預批嘅假期，作出最終簽批以扣減假期額及發放薪酬。',
    '🛡️ Dual Verification: Supervisor checks shift feasibility; HR validates policies.':
        '🛡️ 雙重審核：主管確認更次人手，人力資源核對假期政策。',
    '⚡ 1-Tap Final Sign-off: One tap marks leave as FULLY APPROVED.':
        '⚡ 一撳最終簽署：一撳即可將假期標記為「已最終批准」。',
    '📉 Automatic Balance Sync: Employee leave balance updates automatically.':
        '📉 自動扣減餘額：員工假期餘額將自動更新。',
    'What You Can Do as HR Admin': '人力資源管理員功能總覽',
    'Quick overview of HR capabilities across bottom navigation tabs.':
        '底部導航欄人力資源管理員功能一覽。',
    'Scan QR Code to Check In': '掃描二維碼上班打卡',
    'You are NOT checked in automatically upon login. Turn on your GPS location and scan the workstation QR code to start your shift.':
        '登入後唔會自動打卡。請開啟 GPS 定位並掃描工作站二維碼以開始更次。',
    'Scan QR Code to Check Out': '掃描二維碼下班打卡',
    'When your shift ends, tap "Scan Check-Out QR" to record your departure and log your total hours.':
        '更次結束後，撳「掃描下班打卡」以記錄離開時間及儲存總工時。',
    'Simulate 1-Tap Approve': '模擬一撳批准',
    '✓ Approved (Tap to Reset)': '✓ 已批准（撳一下重設）',
    'Simulate Staff Registration': '模擬員工登記',
    '✓ Account Ready (Tap to Reset)': '✓ 帳戶就緒（撳一下重設）',
    'Simulate Final HR Sign-off': '模擬人力資源最終簽批',
    '✓ Final Signed Off (Reset)': '✓ 最終簽批完成（重設）',
    'Tap to Simulate QR Scan': '撳一下模擬掃描二維碼',
  };
}
