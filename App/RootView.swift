import SwiftUI

enum CRMTab: String, CaseIterable { case home = "Nhà", properties = "BĐS", customers = "Khách", ai = "AI"
    var icon: String { switch self { case .home: return "house"; case .properties: return "building.2"; case .customers: return "person.2"; case .ai: return "sparkles" } }
    var title: String { switch self { case .home: return "LẮM AI CRM"; case .properties: return "Quỹ bất động sản"; case .customers: return "Khách hàng"; case .ai: return "AI Copilot" } }
}
enum CRMRoute: String, Hashable, CaseIterable {
    case newProperty = "Thêm BĐS", newCustomer = "Thêm khách"
    case tasks = "Công việc", urgent = "Việc cần gấp", calendar = "Lịch hẹn", matching = "Matching hai chiều", settings = "Cài đặt", reports = "Báo cáo & sao lưu", search = "Tìm kiếm", requirements = "Nhu cầu khách"
}

struct RootView: View {
    @EnvironmentObject var store: CRMStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: CRMTab = .home
    @State private var path: [CRMRoute] = []
    @State private var quick = false
    var body: some View {
        NavigationStack(path:$path) {
            Group {
                if !store.ready { ProgressView("Đang mở không gian làm việc…") }
                else {
                    switch tab {
                    case .home: HomeOverview { path.append($0) }
                    case .properties: PropertiesView()
                    case .customers: CustomersView()
                    case .ai: AIIntakeView()
                    }
                }
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(CRMStyle.background)
            .navigationTitle(tab.title)
            .toolbarBackground(CRMStyle.green,for:.navigationBar)
            .toolbarBackground(.visible,for:.navigationBar)
            .toolbarColorScheme(.dark,for:.navigationBar)
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Menu { ForEach(CRMRoute.allCases,id:\.self) { route in Button(route.rawValue) { path.append(route) } } } label: { Image(systemName:"line.3.horizontal").foregroundStyle(.white).accessibilityLabel("Các chức năng") }
                }
            }
            .navigationDestination(for:CRMRoute.self) { route in
                routeView(route).navigationTitle(route.rawValue).background(CRMStyle.background)
            }
            .safeAreaInset(edge:.bottom,spacing:0) {
                HStack(spacing:0) {
                    tabButton(.home); tabButton(.properties)
                    Button { quick = true } label: { Image(systemName:"plus").font(.title2.bold()).frame(width:54,height:54).foregroundStyle(.white).background(CRMStyle.green,in:RoundedRectangle(cornerRadius:17)) }
                        .accessibilityLabel("Thêm mới").accessibilityIdentifier("quickAdd").frame(maxWidth:.infinity)
                    tabButton(.customers); tabButton(.ai)
                }.padding(.vertical,10).background(.white)
            }
        }
        .tint(CRMStyle.green)
        .onChange(of:scenePhase) {_,phase in if phase == .active {Task {await store.refreshReminders()}}}
        .sheet(isPresented:$quick) {
            NavigationStack {
                List {
                    Button("BĐS thủ công") { quick = false; tab = .properties; path = [.newProperty] }
                    Button("Khách hàng") { quick = false; tab = .customers; path = [.newCustomer] }
                    Button("Nhu cầu khách") { quick = false; path.append(.requirements) }
                    Button("Công việc / lịch hẹn") { quick = false; path.append(.tasks) }
                    Button("Dán tin / ảnh / giọng nói → AI") { quick = false; tab = .ai; path = [] }
                }.navigationTitle("Bạn muốn thêm gì?").toolbar { ToolbarItem(placement:.cancellationAction) { Button("Đóng") { quick = false } } }
            }.presentationDetents([.medium,.large])
        }
        .alert("Thông báo",isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error = nil}})) { Button("Đóng",role:.cancel) { store.error = nil } } message: { Text(store.error ?? "") }
    }
    private func tabButton(_ item:CRMTab) -> some View {
        Button { tab = item; path = [] } label: { VStack(spacing:5) { Image(systemName:item.icon).font(.title3); Text(item.rawValue).font(.caption) }.frame(maxWidth:.infinity,minHeight:44).foregroundStyle(tab == item ? CRMStyle.green : .secondary) }.accessibilityIdentifier("tab-"+item.rawValue)
    }
    @ViewBuilder private func routeView(_ route:CRMRoute) -> some View {
        switch route {
        case .newProperty: PropertyEditor(record:PropertyLogic.newDraft())
        case .newCustomer: CustomerEditor(customer:CustomerLogic.newCustomer(),needs:[])
        case .tasks,.calendar,.urgent: TasksView(calendar:route == .calendar,urgent:route == .urgent)
        case .requirements: RequirementsView()
        case .search: SearchView()
        case .settings,.reports: ScrollView { CRMPanel { Text(store.data.settings["brand"].text).font(.headline); Text(store.data.settings["phone"].text); Text("SQLite trên iPhone"); Text("Không cần đăng nhập Firebase để dùng dữ liệu trên máy.").font(.footnote) }.padding() }
        case .matching: CRMEmpty(title:"Matching hai chiều",detail:"Đề xuất từ 70% và đáp ứng điều kiện bắt buộc. Điểm không phải xác suất giao dịch.").padding()
        }
    }
}

struct HomeOverview: View {
    @EnvironmentObject var store: CRMStore
    var navigate: (CRMRoute)->Void
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:16) {
                Text("Hôm nay cần làm gì?").font(.title2.bold())
                Text(Date.now,format:.dateTime.weekday(.wide).day().month().year()).font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
                    stat("BĐS đang bán",store.data.properties.filter{$0.text("status") == "ACTIVE"}.count,"building.2")
                    stat("Khách hàng",store.data.customers.count,"person.2")
                    stat("Nhu cầu đang tìm",store.data.requirements.filter{$0.text("status") == "ACTIVE"}.count,"target")
                    Button { navigate(.tasks) } label: { stat("Việc cần làm",store.data.tasks.filter{$0.text("status") == "TODO"}.count,"checklist") }.buttonStyle(.plain)
                }
                CRMPanel {
                    Text("Việc cần xử lý").font(.headline)
                    Button("Việc cần gấp / quá hạn") { navigate(.urgent) }
                    Button("Lịch hẹn") { navigate(.calendar) }
                    Button("Matching hai chiều") { navigate(.matching) }
                }
                Text("Khách đang chờ chăm sóc").font(.headline)
                let pending = TaskLogic.pending(store.data)
                if pending.isEmpty {Text("Chưa có khách cần chăm sóc.").foregroundStyle(.secondary)}
                ForEach(pending.prefix(10)) {c in
                    NavigationLink {CustomerDetail(id:c.id)} label:{CRMPanel {
                        Text(c.title).font(.headline);Text(c.text("status"))
                        let tasks = store.data.tasks.filter{$0.text("customerId") == c.id && $0.text("status") == "TODO"}
                        Text(tasks.contains{TaskLogic.overdue($0)} ? "Có lịch quá hạn" : tasks.isEmpty ? "Chưa có lịch chăm sóc" : "\(tasks.count) việc đang chờ").foregroundStyle(tasks.contains{TaskLogic.overdue($0)} ? .red : CRMStyle.green)
                    }}.buttonStyle(.plain)
                }
                Text("Bất động sản vừa cập nhật").font(.headline)
                if store.data.properties.isEmpty { CRMEmpty(title:"Bắt đầu quỹ hàng đầu tiên",detail:"Nhấn + để chọn cách nhập dữ liệu.") }
                ForEach(store.data.properties.prefix(3)) { PropertySummary(property:$0) }
            }.padding(18)
        }
    }
    private func stat(_ title:String,_ count:Int,_ icon:String)->some View {
        CRMPanel { Label(title,systemImage:icon).font(.subheadline); Text("\(count)").font(.largeTitle.bold()).foregroundStyle(CRMStyle.green) }
    }
}

struct RecordList: View {
    @EnvironmentObject var store: CRMStore
    let collection:String
    var urgent = false
    @State private var query = ""
    var items:[CRMRecord] {
        store.data[collection].filter { r in
            let search = query.isEmpty || [r.title,r.text("phone"),r.text("location.wardCommune"),r.text("note")].joined(separator:" ").localizedStandardContains(query)
            let due = Database.date(r.text("dueAt")) ?? .distantFuture
            return search && (!urgent || (r.text("status") == "TODO" && (r.text("priority") == "URGENT" || due <= Date())))
        }
    }
    var body:some View {
        ScrollView { LazyVStack(spacing:14) {
            if items.isEmpty { CRMEmpty(title:"Chưa có dữ liệu trong mục này") }
            ForEach(items) { record in
                if collection == "properties" { PropertySummary(property:record) }
                else { CRMPanel { Text(record.title.isEmpty ? record.text("rawRequirementText") : record.title).font(.headline); Text(record.text("phone")); Text(record.text("note")).font(.subheadline).foregroundStyle(.secondary) } }
            }
        }.padding(18) }.searchable(text:$query,prompt:"Tìm tên, số điện thoại, khu vực…")
    }
}

struct SearchView: View {
    @EnvironmentObject var store: CRMStore
    @State private var query = ""
    var results:[CRMRecord] { guard !query.isEmpty else { return [] }; return (store.data.properties+store.data.customers).filter { record in ["title","name","code","phone","owner.phone","location.wardCommune","location.addressText","details","note"].map{record.text($0)}.joined(separator:" ").localizedStandardContains(query) || record.strings("tags").joined(separator:" ").localizedStandardContains(query) } }
    var body:some View { List { ForEach(results) { Text($0.title) } }.searchable(text:$query,prompt:"BĐS, khách, điện thoại, phường, ghi chú…") }
}
