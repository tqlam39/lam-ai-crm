import SwiftUI

struct CustomersView: View {
    @EnvironmentObject var store:CRMStore
    @State private var query = ""
    @State private var status = ""
    @State private var priority = ""
    var body:some View {
        ScrollView { LazyVStack(spacing:14) {
            HStack {
                Picker("Giai đoạn",selection:$status) {Text("Mọi giai đoạn").tag("");ForEach(CustomerLogic.statuses,id:\.self){Text($0).tag($0)}}
                Picker("Ưu tiên",selection:$priority) {Text("Mọi ưu tiên").tag("");Text("Bình thường").tag("NORMAL");Text("Cao").tag("HIGH");Text("Gấp").tag("URGENT")}
            }
            let customers = store.data.customers.filter { c in
                (status.isEmpty || c.text("status") == status) && (priority.isEmpty || c.text("priority") == priority) && (query.isEmpty || PropertyLogic.normalizedText([c.title,c.text("phone"),c.text("note")].joined(separator:" ")).contains(PropertyLogic.normalizedText(query)))
            }
            if customers.isEmpty {CRMEmpty(title:"Chưa có khách phù hợp",detail:"Thêm khách và nhu cầu tìm BĐS để quản lý chăm sóc.")}
            ForEach(customers) { c in
                NavigationLink {CustomerDetail(id:c.id)} label: {
                    CRMPanel {
                        Text(c.title).font(.headline);Text(c.text("phone"));Text(c.text("status")).font(.caption).foregroundStyle(CRMStyle.green)
                        Text(c.text("note")).font(.subheadline).lineLimit(2)
                        Text("\(store.data.requirements.filter{$0.text("customerId") == c.id && $0.text("status") == "ACTIVE"}.count) nhu cầu đang tìm").font(.caption)
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("customer-"+c.id)
            }
        }.padding(18) }.searchable(text:$query,prompt:"Tên, số điện thoại, ghi chú…")
        .toolbar {ToolbarItem(placement:.topBarTrailing) {NavigationLink {CustomerEditor(customer:CustomerLogic.newCustomer(),needs:[])} label:{Label("Thêm khách",systemImage:"plus")}.accessibilityIdentifier("add-customer")}}
    }
}

struct CustomerEditor:View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) private var dismiss
    @State var customer:CRMRecord
    @State var needs:[CRMRecord]
    @State private var error = ""
    var body:some View {
        Form {
            Section("Thông tin khách") {
                TextField("Tên khách *",text:text("name")).autocorrectionDisabled().accessibilityIdentifier("customer-name")
                TextField("Số điện thoại",text:text("phone")).keyboardType(.phonePad)
                TextField("Zalo / số điện thoại",text:text("zalo"))
                TextField("Facebook",text:text("facebook"));TextField("Nguồn khách",text:text("source"))
                Picker("Giai đoạn",selection:text("status")) {
                    ForEach(Array(Set(CustomerLogic.statuses+[customer.text("status")])).sorted(),id:\.self){Text($0).tag($0)}
                }
                Picker("Ưu tiên",selection:text("priority")) {Text("Bình thường").tag("NORMAL");Text("Cao").tag("HIGH");Text("Gấp").tag("URGENT")}
                TextField("Ghi chú",text:text("note"),axis:.vertical).lineLimit(3...8)
            }
            Section {
                Text("Tất cả tiêu chí tìm BĐS đều có thể bỏ trống.").foregroundStyle(.secondary)
                ForEach(needs.indices,id:\.self) { i in NavigationLink {NeedFields(record:$needs[i])} label:{NeedSummary(record:needs[i])} }
                Button("Thêm nhu cầu khác") {needs.append(CustomerLogic.newNeed(customerId:customer.id))}
            } header:{Text("Nhu cầu tìm bất động sản")}
            if !error.isEmpty {Text(error).foregroundStyle(.red)}
        }.navigationTitle("Thông tin khách")
        .toolbar {ToolbarItem(placement:.confirmationAction) {Button("Lưu") {save()}.disabled(store.busy).accessibilityIdentifier("save-customer")}}
        .onAppear {if needs.isEmpty {needs = [CustomerLogic.newNeed(customerId:customer.id)]}}
    }
    private func text(_ key:String)->Binding<String> {Binding(get:{customer.text(key)},set:{customer[key] = .string($0)})}
    private func save() {
        Task {do {try await store.commit(entity:customer.id,action:"Lưu khách và nhu cầu") {try CustomerLogic.save(customer,needs:needs,into:&$0)};dismiss()} catch {self.error = error.localizedDescription}}
    }
}

struct NeedSummary:View {
    let record:CRMRecord
    var body:some View {
        VStack(alignment:.leading,spacing:8) {
            Text(record.strings("propertyTypes").map{CRMStyle.types[$0] ?? $0}.joined(separator:", ").isEmpty ? "Mọi loại BĐS" : record.strings("propertyTypes").map{CRMStyle.types[$0] ?? $0}.joined(separator:", ")).font(.headline)
            Text(record.strings("wardCommunes").isEmpty ? "Không giới hạn khu vực" : record.strings("wardCommunes").joined(separator:", "))
            Text("Từ \(record.number("priceMin").map{CRMStyle.money($0)} ?? "bất kỳ") • Đến \(record.number("priceMax").map{CRMStyle.money($0)} ?? "bất kỳ")").font(.subheadline)
            Text(record.text("rawRequirementText")).font(.subheadline)
            Text(["ACTIVE":"Đang tìm","PAUSED":"Tạm dừng","FULFILLED":"Đã đáp ứng"][record.text("status")] ?? record.text("status")).font(.caption).foregroundStyle(CRMStyle.green)
        }
    }
}

struct CustomerDetail:View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) private var dismiss
    let id:String
    @State private var remove = false
    var body:some View {
        Group {
            if let c = store.data.customers.first(where:{$0.id == id}) {
                List {
                    Section("Hồ sơ khách") {
                        Text(c.title).font(.title2.bold());Text(c.text("status"));Text(c.text("phone"));Text(c.text("note"))
                        HStack {if let url = CustomerLogic.phone(c) {Link("Gọi khách",destination:url)};Spacer();if let url = CustomerLogic.zalo(c) {Link("Zalo",destination:url)}}
                        NavigationLink("Sửa thông tin / nhu cầu") {CustomerEditor(customer:c,needs:store.data.requirements.filter{$0.text("customerId") == id})}
                    }
                    Section("Nhu cầu tìm BĐS") {
                        ForEach(store.data.requirements.filter{$0.text("customerId") == id}) {r in NavigationLink {RequirementEditor(record:r)} label:{NeedSummary(record:r)}}
                        NavigationLink("Thêm nhu cầu") {RequirementEditor(record:CustomerLogic.newNeed(customerId:id))}
                    }
                    Section("Chăm sóc / lịch hẹn") {
                        NavigationLink("Ghi kết quả / hẹn chăm sóc tiếp") {CareEditor(customerId:id)}
                        ForEach(store.data.tasks.filter{$0.text("customerId") == id}) {t in VStack(alignment:.leading) {Text(t.title).font(.headline);Text(t.text("note"));Text(t.text("dueAt")).font(.caption);Text(t.text("status"))}}
                    }
                    Section("Lịch sử") {ForEach(store.data.activities.filter{$0.text("entityId") == id}) {a in VStack(alignment:.leading){Text(a.text("action"));Text(a.text("at")).font(.caption).foregroundStyle(.secondary)}}}
                    Button("Xóa khách",role:.destructive) {remove = true}
                }.navigationTitle(c.title)
            } else {CRMEmpty(title:"Không tìm thấy khách").padding()}
        }.confirmationDialog("Xóa khách và các nhu cầu? Công việc được giữ và gỡ liên kết khách.",isPresented:$remove,titleVisibility:.visible) {
            Button("Xóa khách",role:.destructive) {Task {do {try await store.commit(entity:id,action:"Xóa khách và nhu cầu"){CustomerLogic.delete(id,from:&$0)};dismiss()} catch {store.error = error.localizedDescription}}}
        }
    }
}

struct RequirementsView:View {
    @EnvironmentObject var store:CRMStore
    var body:some View {List {
        ForEach(store.data.requirements) {r in NavigationLink {RequirementEditor(record:r)} label:{VStack(alignment:.leading) {Text(store.data.customers.first{$0.id == r.text("customerId")}?.title ?? "Khách không còn tồn tại").font(.caption);NeedSummary(record:r)}}}
        NavigationLink("Thêm nhu cầu") {RequirementEditor(record:CustomerLogic.newNeed(customerId:""))}
    }}
}

struct RequirementEditor:View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) private var dismiss
    @State var record:CRMRecord
    @State private var error = ""
    var body:some View {
        NeedFields(record:$record) {
            Picker("Khách hàng",selection:Binding(get:{record.text("customerId")},set:{record["customerId"] = .string($0)})) {Text("Chọn khách").tag("");ForEach(store.data.customers){Text($0.title).tag($0.id)}}
            if !error.isEmpty {Text(error).foregroundStyle(.red)}
        }.toolbar {ToolbarItem(placement:.confirmationAction) {Button("Lưu") {Task {do {
            try Validation.requirement(record)
            try await store.commit(entity:record.text("customerId"),action:"Lưu nhu cầu") {d in
                try Validation.require(d.customers.contains{$0.id == record.text("customerId")},"Chọn khách hàng.");d.upsert(record,into:"requirements")
            };dismiss()
        } catch {self.error = error.localizedDescription}}}.disabled(store.busy)}}
    }
}
