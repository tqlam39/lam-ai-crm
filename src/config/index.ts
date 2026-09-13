export const propertyTypes = { HOUSE: 'Nhà', LAND: 'Đất nền', AGRICULTURAL_LAND: 'Đất nông nghiệp', WAREHOUSE: 'Kho xưởng' } as const;
export const transactions = { SALE: 'Mua bán', RENT: 'Cho thuê' } as const;
export const statuses = { ACTIVE: 'Đang bán', SOLD: 'Đã bán', PAUSED: 'Tạm ngưng' } as const;
export const directions = { E: 'Đông', S: 'Nam', W: 'Tây', N: 'Bắc', NW: 'Tây Bắc', SW: 'Tây Nam', NE: 'Đông Bắc', SE: 'Đông Nam' } as const;
export const favoriteAreas = ['Phường Phú Lợi', 'Phường Mỹ Xuyên', 'Phường Sóc Trăng', 'Xã Trần Đề'];
export const defaultSettings = { brand: 'Lắm BĐS Sóc Trăng', phone: '0946 261 719', favoriteAreas, weights: { area:25, price:20, type:15, dimensions:10, bedrooms:10, direction:5, legal:5, car:5, semantic:5 } };
export const money = (n: number) => n >= 1e9 ? `${(n/1e9).toLocaleString('vi-VN',{maximumFractionDigits:2})} tỷ` : `${(n/1e6).toLocaleString('vi-VN',{maximumFractionDigits:2})} triệu`;
export const MATCH_RECOMMENDATION_THRESHOLD = 70;

export const certificateStatuses = { RED_BOOK: 'Sổ đỏ', NO_CERTIFICATE: 'Chưa có sổ' } as const;

