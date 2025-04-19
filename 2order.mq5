//+------------------------------------------------------------------+
//|                                                 2OrderExpert.mq5 |
//|                        Copyright 2023, Farnad Tech               |
//|                                  https://www.farnadtech.com      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Farnad Tech"
#property link      "https://www.farnadtech.com"
#property version   "1.00"
#property description "اکسپرت سفارش دوتایی با قیمت ورودی کاربر - ساخته شده توسط Farnad Tech"
#property strict

#include <Trade\Trade.mqh>

// متغیرهای ورودی
input double RiskPercent = 1.0;         // درصد ریسک (درصد از حساب)
input int    MagicNumber = 123456;      // شماره شناسایی سفارش‌ها

// متغیرهای گلوبال
CTrade   trade;                         // آبجکت معاملات
bool     isPanel = false;               // وجود پنل در چارت
string   prefixName = "2OrderExpert_";  // پیشوند اشیاء
bool     useSpread = true;              // استفاده از اسپرد (true) یا پیپ ثابت (false)
int      fixedPips = 10;                // مقدار پیپ ثابت

// آیدی اشیاء پنل
int      inputPrice_ID = 1;
int      inputSL_ID = 2;
int      inputRR_ID = 3;
int      inputRisk_ID = 4;
int      inputSpread_ID = 5;
int      inputPips_ID = 6;
int      buttonBuy_ID = 7;
int      buttonSell_ID = 8;
int      buttonClose_ID = 9;
int      buttonWebsite_ID = 10;         // دکمه بازدید از سایت
int      buttonContact_ID = 11;         // دکمه تماس با ما

//+------------------------------------------------------------------+
//| ایجاد پنل کاربری                                                |
//+------------------------------------------------------------------+
void CreatePanel()
{
   if(isPanel) return;
   
   // پاکسازی اشیاء قبلی
   ObjectsDeleteAll(0, prefixName);
   
   // تنظیمات پنل
   int x = 20;
   int y = 20;
   int width = 700;   // افزایش عرض پنل
   int height = 540;  // حفظ ارتفاع قبلی
   
   // تعیین موقعیت‌های استاندارد
   int leftSectionWidth = 400;   // عرض بخش سمت چپ
   int rightX = x + leftSectionWidth + 10;  // موقعیت X برای شروع بخش راست
   
   // ایجاد پس‌زمینه پنل
   if(!ObjectCreate(0, prefixName+"panel", OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_YSIZE, height);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_BGCOLOR, clrWhiteSmoke);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_BACK, false);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, prefixName+"panel", OBJPROP_HIDDEN, true);
   
   // خط جداکننده عمودی
   if(!ObjectCreate(0, prefixName+"vertical_separator", OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_XDISTANCE, x + leftSectionWidth);
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_YDISTANCE, y + 10);
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_XSIZE, 2);
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_YSIZE, height - 20);
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_BGCOLOR, clrSilver);
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefixName+"vertical_separator", OBJPROP_BACK, false);
   
   //----- بخش چپ: تنظیمات اصلی اکسپرت -----
   
   // عنوان پنل
   if(!ObjectCreate(0, prefixName+"title", OBJ_LABEL, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, prefixName+"title", OBJPROP_XDISTANCE, x + 120);
   ObjectSetInteger(0, prefixName+"title", OBJPROP_YDISTANCE, y + 15);
   ObjectSetString(0, prefixName+"title", OBJPROP_TEXT, "اکسپرت سفارش دوتایی");
   ObjectSetInteger(0, prefixName+"title", OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, prefixName+"title", OBJPROP_COLOR, clrNavy);
   ObjectSetString(0, prefixName+"title", OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, prefixName+"title", OBJPROP_SELECTABLE, false);
   
   int labelX = x + 20;         // موقعیت X برچسب‌ها
   int inputX = x + 180;        // موقعیت X فیلدهای ورودی
   int rowHeight = 40;          // فاصله بین ردیف‌ها
   int startY = y + 60;         // شروع Y برای اولین ردیف
   int currentRow = 0;          // شمارنده ردیف‌ها
   
   // ردیف 1: قیمت ورودی
   CreateLabel(prefixName+"label_price", "قیمت ورودی:", labelX, startY + (currentRow * rowHeight));
   CreateEdit(prefixName+"input_price", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits), 
              inputX, startY + (currentRow * rowHeight), 180, 30, inputPrice_ID);
   currentRow++;
   
   // ردیف 2: قیمت حد ضرر
   double defaultSL = 0;
   if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > 0)
      defaultSL = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (50 * SymbolInfoDouble(_Symbol, SYMBOL_POINT));
   
   CreateLabel(prefixName+"label_sl", "قیمت حد ضرر:", labelX, startY + (currentRow * rowHeight));
   CreateEdit(prefixName+"input_sl", DoubleToString(defaultSL, _Digits), 
              inputX, startY + (currentRow * rowHeight), 180, 30, inputSL_ID);
   currentRow++;
   
   // ردیف 3: نسبت ریوارد
   CreateLabel(prefixName+"label_rr", "نسبت ریوارد:", labelX, startY + (currentRow * rowHeight));
   CreateEdit(prefixName+"input_rr", "2.0", inputX, startY + (currentRow * rowHeight), 180, 30, inputRR_ID);
   currentRow++;
   
   // ردیف 4: درصد ریسک
   CreateLabel(prefixName+"label_risk", "درصد ریسک:", labelX, startY + (currentRow * rowHeight));
   CreateEdit(prefixName+"input_risk", DoubleToString(RiskPercent, 2), 
              inputX, startY + (currentRow * rowHeight), 180, 30, inputRisk_ID);
   currentRow++;
   
   // ردیف 5: نوع فاصله سفارش دوم
   CreateLabel(prefixName+"label_spread_type", "نوع فاصله سفارش دوم:", labelX, startY + (currentRow * rowHeight));
   CreateButton(prefixName+"button_spread_type", useSpread ? "اسپرد" : "پیپ ثابت", 
                inputX, startY + (currentRow * rowHeight), 180, 30, 
                useSpread ? clrRoyalBlue : clrGoldenrod, 0);
   currentRow++;
   
   // ردیف 6: ضریب اسپرد
   CreateLabel(prefixName+"label_spread", "ضریب اسپرد:", labelX, startY + (currentRow * rowHeight));
   CreateEdit(prefixName+"input_spread", "1", inputX, startY + (currentRow * rowHeight), 180, 30, inputSpread_ID);
   currentRow++;
   
   // ردیف 7: پیپ ثابت
   CreateLabel(prefixName+"label_pips", "پیپ ثابت:", labelX, startY + (currentRow * rowHeight));
   CreateEdit(prefixName+"input_pips", IntegerToString(fixedPips), 
              inputX, startY + (currentRow * rowHeight), 180, 30, inputPips_ID);
   currentRow++;
   
   // تنظیم حالت نمایش بر اساس نوع فاصله انتخابی
   UpdateDistanceFieldsVisibility();
   
   // ردیف 8: توضیحات
   currentRow++;
   CreateLabel(prefixName+"info", "دو سفارش با فاصله مشخص شده ثبت خواهد شد", 
               x + 20, startY + (currentRow * rowHeight));
   
   // ردیف 9: دکمه‌های خرید و فروش
   currentRow++;
   int buttonY = startY + (currentRow * rowHeight);
   CreateButton(prefixName+"button_buy", "خرید", x + 30, buttonY, 160, 50, clrGreen, 0);
   CreateButton(prefixName+"button_sell", "فروش", x + 210, buttonY, 160, 50, clrRed, 0);
   
   // ردیف 10: دکمه بستن معاملات
   currentRow += 2;
   CreateButton(prefixName+"button_close", "بستن معاملات", 
                x + 100, startY + (currentRow * rowHeight), 190, 40, clrOrange, 0);
   
   // برچسب وضعیت
   currentRow += 1.5;
   CreateLabel(prefixName+"status", "آماده برای معامله", x + 20, startY + (currentRow * rowHeight));

   //----- بخش راست: اطلاعات سازنده -----
   
   // عنوان بخش سازنده
   if(!ObjectCreate(0, prefixName+"developer_section_title", OBJ_LABEL, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, prefixName+"developer_section_title", OBJPROP_XDISTANCE, rightX + 60);
   ObjectSetInteger(0, prefixName+"developer_section_title", OBJPROP_YDISTANCE, y + 40);
   ObjectSetString(0, prefixName+"developer_section_title", OBJPROP_TEXT, "اطلاعات سازنده");
   ObjectSetInteger(0, prefixName+"developer_section_title", OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, prefixName+"developer_section_title", OBJPROP_COLOR, clrNavy);
   ObjectSetString(0, prefixName+"developer_section_title", OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, prefixName+"developer_section_title", OBJPROP_SELECTABLE, false);
   
   // لوگوی سازنده (یک مستطیل با رنگ سازمانی)
   if(!ObjectCreate(0, prefixName+"logo", OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return;
   
   // بزرگتر کردن لوگو و تنظیم موقعیت آن
   int logoWidth = 200;
   int logoHeight = 60;
   int logoX = rightX + 45;
   
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_XDISTANCE, logoX);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_YDISTANCE, y + 70);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_XSIZE, logoWidth);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_YSIZE, logoHeight);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_BGCOLOR, clrMidnightBlue);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, prefixName+"logo", OBJPROP_BACK, false);
   
   // نام شرکت روی لوگو
   if(!ObjectCreate(0, prefixName+"logo_text", OBJ_LABEL, 0, 0, 0))
      return;
   
   // تنظیم متن دقیقاً در وسط لوگو
   ObjectSetInteger(0, prefixName+"logo_text", OBJPROP_XDISTANCE, logoX + (logoWidth / 2) - 40);
   ObjectSetInteger(0, prefixName+"logo_text", OBJPROP_YDISTANCE, y + 95);
   ObjectSetString(0, prefixName+"logo_text", OBJPROP_TEXT, "Farnad Tech");
   ObjectSetInteger(0, prefixName+"logo_text", OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, prefixName+"logo_text", OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, prefixName+"logo_text", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, prefixName+"logo_text", OBJPROP_SELECTABLE, false);
   
   // اطلاعات تماس
   int infoStartY = y + 150;
   int infoRowHeight = 30;
   
   // نام سازنده
   CreateLabel(prefixName+"label_developer", "ساخته شده توسط: Farnad Tech", 
               rightX + 10, infoStartY, clrDarkBlue);
   
   // وب‌سایت
   CreateLabel(prefixName+"label_website_info", "وب‌سایت: www.farnadtech.com", 
               rightX + 10, infoStartY + infoRowHeight, clrDarkBlue);
   
   // ایمیل
   CreateLabel(prefixName+"label_email", "ایمیل: info@farnadtech.com", 
               rightX + 10, infoStartY + (2 * infoRowHeight), clrDarkBlue);
   
   // تلگرام
   CreateLabel(prefixName+"label_telegram", "تلگرام: @farnad_tech", 
               rightX + 10, infoStartY + (3 * infoRowHeight), clrDarkBlue);
   
   // توضیحات محصول
   int descY = infoStartY + (5 * infoRowHeight);
   CreateLabel(prefixName+"label_product_info", "درباره محصول:", 
               rightX + 10, descY, clrDarkBlue, 12);
   
   string descriptions[] = {
      "این اکسپرت به شما امکان می‌دهد",
      "دو سفارش همزمان با فاصله",
      "مشخص از یکدیگر ثبت کنید.",
      "حجم معامله بر اساس ریسک",
      "و فاصله استاپ لاس تعیین می‌شود."
   };
   
   for(int i=0; i<ArraySize(descriptions); i++) {
      CreateLabel(prefixName+"label_desc_" + IntegerToString(i), descriptions[i], 
                  rightX + 10, descY + ((i+1) * 25), clrGray);
   }
   
   // دکمه‌های ارتباطی - جابجایی به پایین‌تر از توضیحات محصول
   int contactButtonY = descY + ((ArraySize(descriptions) + 2) * 25);
   
   // افزایش فاصله بین دکمه‌ها
   CreateButton(prefixName+"button_website", "بازدید از سایت", 
                rightX + 40, contactButtonY, 150, 40, clrDodgerBlue, buttonWebsite_ID);
   
   CreateButton(prefixName+"button_contact", "تماس با ما", 
                rightX + 40, contactButtonY + 50, 150, 40, clrMediumSeaGreen, buttonContact_ID);
   
   isPanel = true;
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| به‌روزرسانی نمایش فیلدهای مربوط به فاصله سفارش دوم               |
//+------------------------------------------------------------------+
void UpdateDistanceFieldsVisibility()
{
   if(useSpread)
   {
      // نمایش فیلد ضریب اسپرد و مخفی کردن فیلد پیپ ثابت
      ObjectSetInteger(0, prefixName+"label_spread", OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, prefixName+"input_spread", OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, prefixName+"input_spread", OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, prefixName+"input_spread", OBJPROP_BORDER_COLOR, clrGray);
      
      ObjectSetInteger(0, prefixName+"label_pips", OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, prefixName+"input_pips", OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, prefixName+"input_pips", OBJPROP_BGCOLOR, clrGainsboro);
      ObjectSetInteger(0, prefixName+"input_pips", OBJPROP_BORDER_COLOR, clrLightGray);
   }
   else
   {
      // نمایش فیلد پیپ ثابت و مخفی کردن فیلد ضریب اسپرد
      ObjectSetInteger(0, prefixName+"label_spread", OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, prefixName+"input_spread", OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, prefixName+"input_spread", OBJPROP_BGCOLOR, clrGainsboro);
      ObjectSetInteger(0, prefixName+"input_spread", OBJPROP_BORDER_COLOR, clrLightGray);
      
      ObjectSetInteger(0, prefixName+"label_pips", OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, prefixName+"input_pips", OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, prefixName+"input_pips", OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, prefixName+"input_pips", OBJPROP_BORDER_COLOR, clrGray);
   }
   
   // به‌روزرسانی عنوان دکمه انتخاب نوع فاصله
   ObjectSetString(0, prefixName+"button_spread_type", OBJPROP_TEXT, useSpread ? "اسپرد" : "پیپ ثابت");
   ObjectSetInteger(0, prefixName+"button_spread_type", OBJPROP_BGCOLOR, useSpread ? clrRoyalBlue : clrGoldenrod);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ایجاد برچسب                                                      |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color textColor = clrBlack, int fontSize = 10)
{
   if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| ایجاد فیلد ورودی                                                |
//+------------------------------------------------------------------+
void CreateEdit(string name, string text, int x, int y, int width = 150, int height = 20, int id = 0)
{
   if(!ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   
   // تنظیم آیدی مربوطه برای شناسایی در رویدادها
   ObjectSetInteger(0, name, OBJPROP_CHART_ID, id);
}

//+------------------------------------------------------------------+
//| ایجاد دکمه                                                      |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color bgColor, int id = 0)
{
   if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| به‌روزرسانی متن برچسب‌ها                                         |
//+------------------------------------------------------------------+
void SetLabelText(string name, string text)
{
   if(ObjectFind(0, name) >= 0)
      ObjectSetString(0, name, OBJPROP_TEXT, text);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| خواندن مقدار از فیلد ورودی                                      |
//+------------------------------------------------------------------+
string GetEditText(string name)
{
   if(ObjectFind(0, name) >= 0)
      return ObjectGetString(0, name, OBJPROP_TEXT);
   
   return "";
}

//+------------------------------------------------------------------+
//| تابع خرید                                                        |
//+------------------------------------------------------------------+
void OnBuyClick()
{
   double entryPrice = StringToDouble(GetEditText(prefixName+"input_price"));
   double stopLoss = StringToDouble(GetEditText(prefixName+"input_sl"));
   double rewardRatio = StringToDouble(GetEditText(prefixName+"input_rr"));
   double riskPercent = StringToDouble(GetEditText(prefixName+"input_risk"));
   int spreadMultiplier = (int)StringToInteger(GetEditText(prefixName+"input_spread"));
   int fixedPipsValue = (int)StringToInteger(GetEditText(prefixName+"input_pips"));
   
   if(entryPrice <= 0 || stopLoss <= 0 || rewardRatio <= 0 || riskPercent <= 0) {
      SetLabelText(prefixName+"status", "خطا: لطفاً مقادیر معتبر وارد کنید");
      return;
   }
   
   if(useSpread && spreadMultiplier <= 0) {
      SetLabelText(prefixName+"status", "خطا: ضریب اسپرد باید بزرگتر از صفر باشد");
      return;
   }
   
   if(!useSpread && fixedPipsValue <= 0) {
      SetLabelText(prefixName+"status", "خطا: مقدار پیپ باید بزرگتر از صفر باشد");
      return;
   }
   
   // محاسبه حد سود بر اساس نسبت ریوارد
   double riskDistance = MathAbs(entryPrice - stopLoss);
   double rewardDistance = riskDistance * rewardRatio;
   double takeProfit = entryPrice + rewardDistance;
   
   // ثبت سفارش‌ها
   PlaceOrders(entryPrice, stopLoss, takeProfit, riskPercent, spreadMultiplier, fixedPipsValue, true);
}

//+------------------------------------------------------------------+
//| تابع فروش                                                        |
//+------------------------------------------------------------------+
void OnSellClick()
{
   double entryPrice = StringToDouble(GetEditText(prefixName+"input_price"));
   double stopLoss = StringToDouble(GetEditText(prefixName+"input_sl"));
   double rewardRatio = StringToDouble(GetEditText(prefixName+"input_rr"));
   double riskPercent = StringToDouble(GetEditText(prefixName+"input_risk"));
   int spreadMultiplier = (int)StringToInteger(GetEditText(prefixName+"input_spread"));
   int fixedPipsValue = (int)StringToInteger(GetEditText(prefixName+"input_pips"));
   
   if(entryPrice <= 0 || stopLoss <= 0 || rewardRatio <= 0 || riskPercent <= 0) {
      SetLabelText(prefixName+"status", "خطا: لطفاً مقادیر معتبر وارد کنید");
      return;
   }
   
   if(useSpread && spreadMultiplier <= 0) {
      SetLabelText(prefixName+"status", "خطا: ضریب اسپرد باید بزرگتر از صفر باشد");
      return;
   }
   
   if(!useSpread && fixedPipsValue <= 0) {
      SetLabelText(prefixName+"status", "خطا: مقدار پیپ باید بزرگتر از صفر باشد");
      return;
   }
   
   // محاسبه حد سود بر اساس نسبت ریوارد
   double riskDistance = MathAbs(entryPrice - stopLoss);
   double rewardDistance = riskDistance * rewardRatio;
   double takeProfit = entryPrice - rewardDistance;
   
   // ثبت سفارش‌ها
   PlaceOrders(entryPrice, stopLoss, takeProfit, riskPercent, spreadMultiplier, fixedPipsValue, false);
}

//+------------------------------------------------------------------+
//| تابع بستن معاملات                                                |
//+------------------------------------------------------------------+
void OnCloseClick()
{
   CloseAllOrders();
   SetLabelText(prefixName+"status", "تمام معاملات بسته شدند");
}

//+------------------------------------------------------------------+
//| ثبت سفارش‌ها                                                     |
//+------------------------------------------------------------------+
void PlaceOrders(double entryPrice, double stopLoss, double takeProfit, double riskPercent, 
                int spreadMultiplier, int fixedPipsValue, bool isBuy)
{
   // محاسبه حجم معامله بر اساس ریسک
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * riskPercent / 100.0;
   
   // محاسبه فاصله استاپ لاس
   double stopLossDistance = MathAbs(entryPrice - stopLoss);
   if(stopLossDistance <= 0) {
      SetLabelText(prefixName+"status", "خطا: فاصله حد ضرر نباید صفر باشد");
      return;
   }
   
   // محاسبه ارزش هر پیپ
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double pointsPerLot = stopLossDistance / tickSize;
   double moneyPerLot = pointsPerLot * tickValue;
   
   // محاسبه حجم کل
   double lotSize = NormalizeDouble(riskAmount / moneyPerLot, 2);
   
   // محدود کردن حجم معامله به محدوده مجاز
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lotSize = MathMax(minLot, MathMin(lotSize, maxLot));
   lotSize = NormalizeDouble(lotSize, 2);
   
   // تقسیم حجم بین دو معامله
   double lotSize1 = NormalizeDouble(lotSize / 2, 2);
   double lotSize2 = NormalizeDouble(lotSize - lotSize1, 2);
   
   // محاسبه قیمت برای معامله دوم
   double entryPrice2;
   
   if(useSpread) {
      // استفاده از اسپرد لحظه‌ای × ضریب
      double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      if(isBuy) {
         entryPrice2 = entryPrice + (spreadMultiplier * spread);
      } else {
         entryPrice2 = entryPrice - (spreadMultiplier * spread);
      }
   } else {
      // استفاده از مقدار پیپ ثابت
      double pipValue = fixedPipsValue * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      if(isBuy) {
         entryPrice2 = entryPrice + pipValue;
      } else {
         entryPrice2 = entryPrice - pipValue;
      }
   }
   
   // ثبت سفارش‌ها
   bool result1 = false;
   bool result2 = false;
   
   // تنظیم مجیک نامبر
   trade.SetExpertMagicNumber(MagicNumber);
   
   if(isBuy) {
      result1 = trade.BuyLimit(lotSize1, entryPrice, _Symbol, stopLoss, takeProfit);
      
      // تنظیم مجیک نامبر برای سفارش دوم
      trade.SetExpertMagicNumber(MagicNumber+1);
      result2 = trade.BuyLimit(lotSize2, entryPrice2, _Symbol, stopLoss, takeProfit);
   } else {
      result1 = trade.SellLimit(lotSize1, entryPrice, _Symbol, stopLoss, takeProfit);
      
      // تنظیم مجیک نامبر برای سفارش دوم
      trade.SetExpertMagicNumber(MagicNumber+1);
      result2 = trade.SellLimit(lotSize2, entryPrice2, _Symbol, stopLoss, takeProfit);
   }
   
   // بازگرداندن مجیک نامبر به مقدار اصلی
   trade.SetExpertMagicNumber(MagicNumber);
   
   // نتیجه عملیات
   if(result1 && result2) {
      SetLabelText(prefixName+"status", "هر دو سفارش با موفقیت ثبت شدند");
   } else {
      string errorText = "خطا در ثبت سفارش: " + (string)GetLastError();
      SetLabelText(prefixName+"status", errorText);
   }
}

//+------------------------------------------------------------------+
//| بستن همه معاملات                                                |
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   // بستن پوزیشن‌های باز
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic == MagicNumber || magic == MagicNumber+1)
      {
         trade.PositionClose(ticket);
      }
   }
   
   // لغو سفارش‌های در انتظار
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket <= 0) continue;
      
      long magic = OrderGetInteger(ORDER_MAGIC);
      if(magic == MagicNumber || magic == MagicNumber+1)
      {
         trade.OrderDelete(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| تابع شروع اکسپرت                                                |
//+------------------------------------------------------------------+
int OnInit()
{
   // تنظیم مجیک نامبر برای معاملات
   trade.SetExpertMagicNumber(MagicNumber);
   
   // ایجاد پنل کاربری
   CreatePanel();
   
   // فعال‌سازی رویدادهای چارت
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   
   // پیغام نمایش پنل
   Print("پنل اکسپرت ایجاد شد. اگر پنل مشاهده نمی‌شود، روی چارت کلیک کنید.");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| تابع پایان کار اکسپرت                                            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // حذف همه اشیاء
   ObjectsDeleteAll(0, prefixName);
   isPanel = false;
}

//+------------------------------------------------------------------+
//| تابع تیک اکسپرت                                                 |
//+------------------------------------------------------------------+
void OnTick()
{
   // اگر پنل وجود ندارد، ایجاد کن
   if(!isPanel)
      CreatePanel();
}

//+------------------------------------------------------------------+
//| مدیریت رویدادهای چارت                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // مدیریت کلیک روی دکمه‌ها
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // چک کردن کلیک روی دکمه خرید
      if(sparam == prefixName+"button_buy")
         OnBuyClick();
      
      // چک کردن کلیک روی دکمه فروش
      else if(sparam == prefixName+"button_sell")
         OnSellClick();
      
      // چک کردن کلیک روی دکمه بستن
      else if(sparam == prefixName+"button_close")
         OnCloseClick();
      
      // چک کردن کلیک روی دکمه تغییر نوع فاصله
      else if(sparam == prefixName+"button_spread_type")
      {
         useSpread = !useSpread;
         UpdateDistanceFieldsVisibility();
      }
      
      // چک کردن کلیک روی دکمه بازدید از سایت
      else if(sparam == prefixName+"button_website")
         OpenWebsite();
         
      // چک کردن کلیک روی دکمه تماس با ما
      else if(sparam == prefixName+"button_contact")
         ContactUs();
   }
}

//+------------------------------------------------------------------+
//| باز کردن سایت سازنده                                             |
//+------------------------------------------------------------------+
void OpenWebsite()
{
   // از آنجا که در MQL5 دسترسی مستقیم به مرورگر وجود ندارد،
   // پیام راهنما برای بازدید از سایت نمایش داده می‌شود
   string message = "لطفاً برای بازدید از سایت به آدرس زیر مراجعه کنید:\n\n";
   message += "https://www.farnadtech.com";
   
   MessageBox(message, "بازدید از سایت Farnad Tech", MB_OK|MB_ICONINFORMATION);
   Print("پیام راهنمای بازدید از سایت Farnad Tech نمایش داده شد");
}

//+------------------------------------------------------------------+
//| تماس با سازنده                                                   |
//+------------------------------------------------------------------+
void ContactUs()
{
   string message = "برای تماس با ما از طریق یکی از روش‌های زیر اقدام کنید:\n\n";
   message += "ایمیل: info@farnadtech.com\n";
   message += "وب‌سایت: https://www.farnadtech.com/contact\n";
   message += "تلگرام: @Farnad_Tech";
   
   MessageBox(message, "تماس با Farnad Tech", MB_OK|MB_ICONINFORMATION);
   Print("پیام راهنمای تماس با Farnad Tech نمایش داده شد");
} 
