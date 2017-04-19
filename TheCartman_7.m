function [p, settings] = TheCartman_7(DATE, OPEN, HIGH, LOW, CLOSE,VOL, OI, exposure, settings)
settings.markets     = {'CASH','F_NG', 'F_CL', 'F_RU','F_GC',...
    'F_US','F_ES','F_RB','F_PA','F_HO',...
    'F_FV','F_HG','F_HO','F_PL', 'F_SI',...
    'F_KC','F_C','F_CT','F_LB','F_BO',...
    'F_OJ','F_AD','F_JY','F_DX','F_CD',...
    'F_EC','F_ED','F_SF','F_BP','F_YM',...
    'F_NQ','F_TY', 'F_O', 'F_SB'};
settings.budget      = 1000000;
settings.slippage    = 0.00;
settings.samplebegin = 19940101;
settings.sampleend   = 20200101;
settings.lookback    = 1504;


% 1Mil Automated Portfolio Allication by Mike Lange =========================
% Quantiacs


% LONG AND SHORT VAR SETTINGS - this lets us know if were still in a
% position
if ~any(strcmp('long',fieldnames(settings)))
    settings.long = 0;
    settings.short = 0;
end

if ~any(strcmp('longF_CL',fieldnames(settings)))
    settings.longF_CL = 0;
    settings.shortF_CL = 0;
end

if ~any(strcmp('ESChaosVar',fieldnames(settings)))
    settings.ESChaosVar = 0;
end

if ~any(strcmp('longF_KC',fieldnames(settings)))
    settings.longF_KC = 0;
    settings.shortF_KC = 0;
end
if ~any(strcmp('longF_BO',fieldnames(settings)))
    settings.longF_BO = 0;
    settings.shortF_BO = 0;
end
if ~any(strcmp('longF_OJ',fieldnames(settings)))
    settings.longF_OJ = 0;
    settings.shortF_OJ = 0;
end
if ~any(strcmp('longF_BP',fieldnames(settings)))
    settings.longF_BP = 0;
    settings.shortF_BP = 0;
end
if ~any(strcmp('longF_SF',fieldnames(settings)))
    settings.longF_SF = 0;
    settings.shortF_SF = 0;
end
if ~any(strcmp('longF_C',fieldnames(settings)))
    settings.longF_C = 0;
    settings.shortF_C = 0;
end
if ~any(strcmp('chfChaosVar',fieldnames(settings)))
    settings.randomRoot = .777;
end
p = zeros(1,numel(settings.markets));

holding = 4;
% A 4 day static holding period
if settings.short ~= 0
    settings.short = rem(settings.short,holding) + 1;
    p(1) = 0;
    p(2) = -1;
end
if settings.short == 0 || settings.short == 4  % go to cash after holdig for 4 days
    p(1) = 1;
    p(2) = 0;
    settings.short = 0;
end
if settings.long ~= 0
    settings.long = rem(settings.long,holding) + 1;
    p(1) = 0;
    p(2) = 1;
end
if settings.long == 0 || settings.long == 4 % go to cash after holdig for 4 days
    p(1) = 1;
    p(2) = 0;
    settings.long = 0;
end

formatDate = datenum(num2str(DATE(end)),'yyyymmdd');
dayOfWeek = weekday(formatDate);



% Added signal confluence with
% 1. a Momentum Oscillator the WilliamsR (My Favorite - inverse of the fast stochastic)
% 2. A trend filter on the CL, so when that close is higher or lower on the
% CL 8 days ago it's been moving! And when that happens gong natural gas with basically fills the liquidity gap
% 3. A volume osc to verify CL is overbought/oversold and fading - again,
% NG to pick up the alpha.
% Pre-optimization - if I do any ind of optimisation on the params at all.
% ==========================================================

%Wiliams R Rule - ON CL
% ==========================================================
% ==========================================================
period1 = 14;%#[7:1:21]#
willr  = indicators([HIGH(end-period1+1:end,3),LOW(end-period1+1:end,3),CLOSE(end-period1+1:end,3)] ,'william',period1);
longrule4 = min(willr(end-7:end-1))<-80 && max(willr(end-2:end))>-80;
shortrule4 = max(willr(end-7:end-1))>-20 && min(willr(end-2:end))<-20;

% ==========================================================
% ==========================================================

%Money Flow index - ON CL -
% ==========================================================
% ==========================================================
%NEED A VOLUME OSCALLATOR - THis is the RSI w/ volume so
%it's a bit more more leading than the RSI, volume ususally leads price so
% its being used as a suplimental momentum osc as an extra || condition
%only as it reduced the amount of trades drastically when it's a && in the
%rule set below - but it's a POWERFUL indicator if used properly..since
%this isn't a mean reversion i loosened up the convential "rules" for the
%MFI
periodmfi = 14;%#[7:1:21]#
mf  = indicators([HIGH(end-30:end,3),LOW(end-30:end,3),CLOSE(end-30:end,3),VOL(end-30:end,3)] ,'mfi',periodmfi);
longrule5 = min(mf(end-15:end-1))<30 && max(mf(end-2:end))>30;
shortrule5 = max(mf(end-15:end-1))>70 && min(mf(end-2:end))<70;
% Trade with the trend - will need to modify the short entry to - may want
% to impliment ROC for the MA
% ==========================================================
periodLongMainStrat   = 50; 
periodRecentMainStrat = 20; 
smaLong   = sum(CLOSE(end-periodLongMainStrat+1:end,2)) / periodLongMainStrat;
smaRecent = sum(CLOSE(end-periodRecentMainStrat+1:end,2)) / periodRecentMainStrat;
longTR = smaRecent >= smaLong;
trendsignallong = longTR;
trendsignalshort = ~longTR;
% ==========================================================

%Volitility increase check with a double ATR lag cross
% ==========================================================
% closeRange = cummax(CLOSE(end-3:end,2));
atr9 = ATR(HIGH, LOW, CLOSE, 9);
atr1 = ATR(HIGH, LOW, CLOSE, 1);

% disclaimer - not my NOT my original idea. But I love the uniqueness of it.
% if oil closes LOWER than the lowest price over the last 8 days &&
% The Close of Natrual Gas is HIGHER than it's close 8 days ago see above
% for the exit, but this entry only
LongRule1 = atr9(2) < atr1(2);
LongRule2 = CLOSE(end,2) <= min(CLOSE(end-8:end,2));
LongRule3 = CLOSE(end,3) > CLOSE(end-8,3);

ShortRule1 = atr9(2) < atr1(2);
ShortRule2 = CLOSE(end,2) >= max(CLOSE(end-8:end,2));
ShortRule3 = CLOSE(end,3) < CLOSE(end-8,3);

% RULE AGGRAGATE - NOTE they are different for long and short //
% TODO: the rulesets may need to be dynamic based on market action
% the willms and mfi assure this for us on the long side but was a hiderane on the short side
% HOWEVER, at a 1.133 SR I'm not going to tough it. Ging to recode this in
% NT so I can do better anaysys. I know, Matlab is for all that - but I
% know NT like the back of my hand so coding this up for walk forward tests
% is important. Untill I figure out how to do all that in. I should have
% reduced the sample sise when building the model soi could on out of sample, but its
% too late now. These markets are prett dynamic and volitale soi do explect
% it to hold up live. <- buying or selling CL did not help...
% ==========================================================
if LongRule1 && LongRule2 && ((LongRule3 && longrule4) || (longrule4 && trendsignallong) || (longrule5&&longrule4));
    p(1) = 0;
    p(2) = 1;
    settings.long = rem(settings.long,holding) + 1;
    settings.short = 0;
end
%relaxed rules as this type of trade naturally works better on shorts as the liquitity gap we are trading has a higher probability of sucess.
%I.E moving out of OIL and into NG is a same sector rotation.
% I want to get the SR up to 2 and will need to add some trades - Possibly
% play the CL oposite NG when the correlation is < 1 between the 2. This
% setup leds itself to a hedge that also generates alpha as a byproduct.
if ShortRule1 && ShortRule2 && (ShortRule3 || shortrule4 || trendsignalshort || shortrule5)
    p(1) = 0;
    p(2) = -1;
    settings.short = rem(settings.short,holding) + 1;
    settings.long = 0;
end

%==========================================================================
%STRATEGY 2 - linear derevation models to represent a dataseries. a rules
%driven tool that genetically (and Swarm) puilds a trading model based on
%the data i coose to replesent it.
%==========================================================================
% These are simple, models that create a traeable synthetic, in a sense.
% All the models below indirectly represent another future contract.
%  this works by evolving formulas from basic building blocks -
% "atomic" functions like add, subtract, multiply, divide, sine, cosine, square root, etc.
% using swarm or genetic regression to build a model, find optimal paramaters, and trade signals.
% These are 'built and optimised' on ~3000 days of in sample then
% tested/verified on ~a thousand days out of sample, then walk fard
% randomness testing and monty carlo simulations to ensure rhobustness
%==========================================================================
%==========================================================================

%//==========================================================/
%// INDEX MODELS  =============================
%//==========================================================/

%//==========================================================/
%// RUSSEL =============================
%//==========================================================/
% Formula:
% Predicted = (Vel(HIGH_ES,11) / %chg(HIGH_DX,2)) + 4.523401
% ----------------
% At next bar OPEN_RU:
%   Buy Long if Predicted >= -2.021518
%   Sell Short if Predicted <= -7.559926  7,24
% if (dayOfWeek == 2 || dayOfWeek == 4)
russelscore = 0;
F_RU_Predicted = (Vel(HIGH(:,7),11) / Pchg(HIGH(:,24),2)) + 4.523401;
if (F_RU_Predicted >= -2.021518)
    p(4)=1;
    russelscore=russelscore+1;
    % buy the other index 7,30,31  // dosent work
elseif(F_RU_Predicted <= -7.559926)
    p(4)=-1;
    russelscore=russelscore-1;
end
% Formula:
%Predicted = ((1/RelStr(LOW_ES,VOL_ES)) - (-5.875014))+ (Vel(HIGH_ES,11) / chg(HIGH_DX,2))
% ----------------
% At next bar OPEN_RU:
%   Buy Long if Predicted >= -1.640869
%   Sell Short if Predicted <= -7.185958
F_RU_Predicted2 = ((1/RelStr(LOW(:,7),VOL(:,7)) - (-5.875014))) + (Vel(HIGH(:,7),11) / Pchg(HIGH(:,24),2));
if (F_RU_Predicted2  >= -1.640869)
    p(4)=1;
     russelscore=russelscore+1;
elseif(F_RU_Predicted2 <= -7.185958)
    p(4)=-1;
     russelscore=russelscore-1;
end
% Formula:
% Predicted = (RelStr(VOL(:,7),LOW(:,30)) - (-6.18047)) + (Vel(HIGH(:,7,11) / Pchg(HIGH(:,24),2))
% ----------------
% At next bar OPEN_RU:
%   Buy Long if Predicted >= -2.459036
%   Sell Short if Predicted <= -10
F_RU_Predicted3 = (RelStr(VOL(:,7),LOW(:,30)) - (-6.18047)) + (Vel(HIGH(:,7),11) / Pchg(HIGH(:,24),2));
if (F_RU_Predicted3 >= -2.459036)
    p(4)=1;
     russelscore=russelscore+1;
elseif(F_RU_Predicted3 <= -10)
    p(4)=-1;
     russelscore=russelscore-1;
end
if(russelscore>2)
        p(4)=1;
elseif(russelscore<-2)
    p(4)=-1;
end

%//==========================================================/
%// ES ============================= // tough to be a long hold - use OI
%and VOL of the ES for inputs to the other indexes
%//==========================================================/
% Formula:
% Predicted = (6.551187 / Vel(OI_CT,45)) - Acc(LOW_ES,6)
% ----------------
% At next bar OPEN_ES:
%   Buy Long if Predicted >= -4.260088
%   Sell Short if Predicted <= -6.947733
F_ES_Predicted1 = (6.551187 / Vel(OI(:,18),45)) - Acc(LOW(:,7),6);
if (F_ES_Predicted1 >= -4.260088)
    p(7)=1;
elseif(F_ES_Predicted1 <=-6.947733)
    p(7)=-1;
end


% Formula:
% Predicted = (Vel(VOL_OJ,44) / 8.162292) - Acc(LOW_ES,6)
% ----------------
% At next bar OPEN_ES:
%   Buy Long if Predicted >= -3.79758
%   Sell Short if Predicted <= -6.593558
F_ES_Predicted2 = (Vel(VOL(:,21),44) / 8.162292) - Acc(LOW(:,7),6);
if (F_ES_Predicted2 >= -3.79758)
    p(7)=.5;
elseif(F_ES_Predicted2 <= -6.593558)
    p(7)=-.5;
end

%// YM ============================= //
% Formula:
% Predicted = (-7.370965) * %chg(OPEN_RU,8)
% ----------------
% At next bar OPEN_YM:
%   Buy Long if Predicted >= -6.717084
%   Sell Short if Predicted <= -6.906605
F_YM_Predicted2 = (-7.370965) * Pchg(OPEN(:,4),8);
if (F_YM_Predicted2 >= -6.717084)
    p(30)=.4;
elseif(F_YM_Predicted2 <= -6.906605)
    p(30)=-.4;
end

% Formula:
% Predicted = (Acc(OI(:,30),32) * Pchg(CLOSE(:,6),35)) - (-3.221498)
% ----------------
% At next bar OPEN_YM:
%   Buy Long if Predicted >= 3.662226
%   Sell Short if Predicted <= -1.12566
F_YM_Predicted3 = (Acc(OI(:,30),32) * Pchg(CLOSE(:,6),35)) - (-3.221498);
if (F_YM_Predicted3 >= 3.662226)
    p(30)=.6;
elseif(F_YM_Predicted3 <= -1.12566)
    p(30)=-.6;
end

% Formula:
% Predicted = -Mom(CLOSE_RU,9)
% ----------------
% At next bar OPEN_YM:
%   Buy Long if Predicted >= 7.572482
%   Sell Short if Predicted <= -9.729137
F_YM_Predicted1 = -Mom(CLOSE(:,4),9);
if (F_YM_Predicted1 >= 7.572482)
    p(30)=1;
elseif(F_YM_Predicted1 <= -9.729137)
    p(30)=-1;
end


%NQ
% Formula:
% Predicted = Vel(OI_ES,1)
% ----------------
% At next bar OPEN_NQ:
%   Buy Long if Predicted >= 8.18747
%   Sell Short if Predicted <= -9.239812
F_NQ_Predicted1 = Vel(OI(:,7),1);
if (F_NQ_Predicted1 >= 8.18747)
    p(31)=1;
elseif(F_NQ_Predicted1 <= -9.239812)
    p(31)=-1;
end


%//==========================================================/
%// BOND MODELS =============================
%//==========================================================/
F_USlongtradescore = 0;
F_USshorttradescore = 0;

%//==========================================================/
%// 30 YEAR =============================
%//==========================================================/
% Formula:
% Predicted = %chg(VOL_RU,46) - Vel(VOL_GC,43)
% ----------------
% At next bar OPEN_US:
%   Buy Long if Predicted >= 8.376322
%   Sell Short if Predicted <= 0.255795
lookback1 = 46;
lookback2 = 43;
Predicted = Pchg(VOL(end-lookback1:end,4),46) - Vel(VOL(end-lookback2:end,5),43);
if (Predicted >= 8.376322)
    p(6)=1;
    % TEN YEAR
    p(32)=.7;
    F_USlongtradescore =F_USlongtradescore+1;
elseif(Predicted <= 0.255795)
    p(6)=0;
    p(32)=0;
    F_USshorttradescore = F_USshorttradescore+1;
end

%======================================================================================================================================================
% MODEL 2
% Formula:
% Predicted = 1/tanh((sin(Sprd(CLOSE_GC,LOW_RU)) / ROC%(HIGH_ES,36)))
% ----------------
% At next bar OPEN_US:
%   Buy Long if Predicted >= 6.028649
%   Sell Short if Predicted <= -4.805673
lookback3 = 36;
mtl2Predicted = 1/tanh((sin(Sprd(CLOSE(:,5),LOW(:,4))) / Proc(HIGH(:,7),lookback3)));
if (mtl2Predicted >= 6.028649)
    p(6)=2;
    p(32)=.7;
    F_USlongtradescore =F_USlongtradescore+1;
    
elseif(mtl2Predicted <= -4.805673)
    p(6)=-2;
    p(32)=-.7;
    F_USshorttradescore = F_USshorttradescore+1;
end
%======================================================================================================================================================


%======================================================================================================================================================
% MODEL 3 // almost identical to model 2 but there is an aditional
% Releative Strength of the Open Interest of ES and HIGH of GC.
% Intersting.. Let's see how it does
%Formula:
% Predicted = (1/(tanh(sin(Sprd(CLOSE_GC,LOW_RU))) / ROC%(LOW_GC,38))) + RelStr(OI_ES,HIGH_RU)
% ----------------
% At next bar OPEN_US:
%   Buy Long if Predicted >= 6.085821
%   Sell Short if Predicted <= -4.354584

lookback4 = 38;
mtl2Predicted = 1/tanh((sin(Sprd(CLOSE(:,5),LOW(:,4))) / Proc(HIGH(:,7),lookback4))) + RelStr(OI(:,7),HIGH(:,4));
if (mtl2Predicted >= 6.085821)
    p(6)=2;
    p(32)=.7; %p(3)=-.4;
    F_USlongtradescore =F_USlongtradescore+1;
elseif(mtl2Predicted <= -4.354584)
    p(6)=-2;
    p(32)=-.7; %p(3)=.4;
    F_USshorttradescore = F_USshorttradescore+1;
end

% F_US scoring and trading
if(F_USlongtradescore>1)
    %p(6)=1;
end
if(F_USshorttradescore>1)
    % p(6)=-1;
end
%======================================================================================================================================================

%==========================================================================
%==========================================================================
%==========================================================================
% COMMODITY MODELS!
%==========================================================================

%======================================================================================================================================================
% /// OIL F_CL Models==============================
% /// OIL F_CL Models==============================
% /// OIL F_CL Models==============================


% Formula:
% Predicted = Sprd(OPEN(:,3),CLOSE(:,3)) * ROC(OI(:,5),5)
% ----------------
% At next bar OPEN_CL:
%   Buy Long if Predicted >= -2.098503
%   Sell Short if Predicted <= -3.227051
F_CL_Predicted3 = Sprd(OPEN(:,3),CLOSE(:,3)) * ROCv(OI(:,5),5);
if (F_CL_Predicted3>= -2.098503)
    p(3)=.5;
    %Crude and Heating Oil are closly corelation - no tests - just pick up
    %a little when allocating to crude
elseif(F_CL_Predicted3 <= -3.227051)
    p(3)=-.5;
end

% Formula:
% Predicted = (Sprd(OPEN_CL,CLOSE_CL) + Acc(HIGH_CL,14)) + cos((-5.123377))
% ----------------
% At next bar OPEN_CL:
%   Buy Long if Predicted >= -1.335096
%   Sell Short if Predicted <= -3.543734
F_CL_Predicted4 = (Sprd(OPEN(:,3),CLOSE(:,3)) + Acc(HIGH(:,3),14)) + cos((-5.123377));
if (F_CL_Predicted4>= -1.335096)
    p(3)=.5;
    
elseif(F_CL_Predicted4 <= -3.543734)
    p(3)=-.5;
 
end

% /// HEATING oIL 10 - F_HL Models=============================

% Formula:
% Predicted = (-%chg(CLOSE_CL,1)) + (1/(ROC(CLOSE_CL,45) / Acc(VOL_HO,36)))
% ----------------
% At next bar OPEN_HO:
%   Buy Long if Predicted >= -2.961325
%   Sell Short if Predicted <= -8.777275
% F_HO_Predicted1 =  (-Pchg(CLOSE(:,3),1)) + (1/(Proc(CLOSE(:,3),45) / Acc(VOL(:,10),36)));
% if (F_HO_Predicted1>=  -2.961325)
%     p(10)=.5;   
% elseif(F_HO_Predicted1 <= -8.777275)
%     p(10)=-.5;
% end
% 
% 
% % Formula:
% % Predicted = 1/(ROC(HIGH_CL,27) / Acc(VOL_HO,36))
% % ----------------
% % At next bar OPEN_HO:
% %   Buy Long if Predicted >= -4.840462
% %   Sell Short if Predicted <= -5.366648
F_HO_Predicted2 =  Acc(VOL(:,10),36);
if (F_HO_Predicted2>= -1.53991)
    p(10)=.5;   
elseif(F_HO_Predicted2 <= -6.684831)
    p(10)=-.5;
end

% Formula:
% Predicted = Acc(VOL_HO,36) / ROC(CLOSE_HO,28)
% ----------------
% At next bar OPEN_HO:
%   Buy Long if Predicted >= -5.03137
%   Sell Short if Predicted <= -5.869934
F_HO_Predicted3 =  Acc(VOL(:,10),36) / ROCv(CLOSE(:,10),28);
if (F_HO_Predicted3>=  -5.03137)
    p(10)=.5;   
elseif(F_HO_Predicted3 <=  -5.869934)
    p(10)=-.5;
end

  
  
% /// F_RB Models==============================
% /// RBOB spot F_CL Models==============================
% Formula:  RB-8  DX -24 ES-7
% Predicted = (ROC(VOL_RB,7) * Vel(LOW_ES,12)) * Sprd(CLOSE_ES,OI_DX)
% ----------------
% At next bar OPEN_RB:
%   Buy Long if Predicted >= 7.770586
%   Sell Short if Predicted <= 6.140196

F_RB_Predicted1 = (ROCv(VOL(:,8),7) * Vel(LOW(:,7),12)) * Sprd(CLOSE(:,24),OI(:,24));
if (F_RB_Predicted1>= 7.770586)
    p(8)=1;
elseif(F_RB_Predicted1 <= 6.140196)
    p(8)=-1;
end
%
% % Formula:
% % Predicted = Vel(VOL_RB,33) * Vel(OI_ES,34)
% % ----------------
% % At next bar OPEN_RB:
% %   Buy Long if Predicted >= 7.058726
% %   Sell Short if Predicted <= 5.871705
F_RB_Predicted1 = Vel(VOL(:,8),33) * Vel(OI(:,7),34);
if (F_RB_Predicted1>= 7.058726)
    p(8)=1;
elseif(F_RB_Predicted1 <= 5.871705)
    p(8)=-1;
end


%   Formula:
% Predicted = n2(0.8397645, Vel(OI_ES,34), 10, sin(10)) * (Vel(VOL_RB,33) * 1.153979)
% ----------------
% At next bar OPEN_RB:
%   Buy Long if Predicted >= 8.556264
%   Sell Short if Predicted <= 5.108956
F_RB_Predicted1 = n2(0.8397645, Vel(OI(:,7),34), 10, sin(10)) * (Vel(VOL(:,8),33) * 1.153979);
if (F_RB_Predicted1>= 8.556264)
    p(8)=1;
elseif(F_RB_Predicted1 <= 5.108956)
    p(8)=-1;
end



%======================================================================================================================================================
%//==========================================================/
%// METALS =============================
%//==========================================================/

%//==========================================================/
%// GOLD =============================
%//==========================================================/
% Formula:
% Predicted = Slope(VOL_FV,12) + Sprd%(OPEN_RU,VOL_CL)
% ----------------
% At next bar OPEN_GC:
%   Buy Long if Predicted >= 8.274952
%   Sell Short if Predicted <= -7.234501
%F_FV is index 11 CL_index 3 RU index=4
F_GC_Predicted = SlopeV(VOL(:,11),12) + SprdP(OPEN(:,4),VOL(:,3));
if (F_GC_Predicted >= 8.274952)
    p(11)=1;
elseif(F_GC_Predicted <= -7.234501)
    p(11)=0;
end
%======================================================================================================================================================

% {'CASH','F_NG', 'F_CL', 'F_RU','F_GC',...
%                         'F_US','F_ES','F_RB','F_PA','F_HO',...
%                         'F_FV','F_HG','F_HO','F_PL', 'F_SI',...
%                         'F_KC','F_C','F_CT','F_LB','F_BO',...
%                         'F_OJ','F_AD','F_JY','F_DX','F_CD',...
%                         'F_EC','F_ED','F_SF','F_BP'};
%======================================================================================================================================================
%//==========================================================/
%// PLATINUM =============================
%//==========================================================/
%
% Predicted = Sprd%(OI_HG,LOW_HG)
% ----------------------------------
% At next bar OPEN_PL: p=14
%   Buy Long if Predicted >= 1.479443
%   Sell Short if Predicted <= 0.338768
%12'F_HG',13'F_HO'
F_PL_Predicted1 = SprdP(OI(:,12),LOW(:,12));
if (F_PL_Predicted1 >= 1.479443)
    p(14)=1;
elseif(F_PL_Predicted1 <= 0.338768)
    p(14)=-1;
end



%======================================================================================================================================================


%======================================================================================================================================================
%//==========================================================/
%// SILVER =============================
%//==========================================================/
% Predicted = Mom(CLOSE_ES,1) - (((-8.738352) - Mom(VOL_US,3)) / Sprd%(OPEN_US,OI_PL))
% ----------------------------------
% At next bar OPEN_SI:
%   Buy Long if Predicted >= 10
%   Sell Short if Predicted <= 0.269239

F_SI_Predicted =  Mom(CLOSE(:,7),1) - (((-8.738352) - Mom(VOL(:,6),3)) / SprdP(OPEN(:,6),OI(:,14)));
if (F_SI_Predicted >= 10)
    p(15)=1;
    %SELL THE DOLLAR
    p(24)=-1;
    %BUY GOLD
    p(5)=1;
elseif(F_SI_Predicted <= 0.269239)
    p(15)=-1;
    %BUY THE DOLLAR
    p(24)=1;
    %SELL GOLD
    p(5)=-1;
end
%======================================================================================================================================================


%======================================================================================================================================================
%//==========================================================/
%// PALLADIUM =============================
%//==========================================================/

% Formula:
% Predicted = ROC(HIGH_EC,4) * ((-0.6859112) * %chg(VOL_DX,19))
% ----------------
% At next bar OPEN_PA:
%   Buy Long if Predicted >= 1.451748
%   Sell Short if Predicted <= -10
F_PA_Predicted2 = ROCv(HIGH(:,26),4) * ((-0.6859112) * Pchg(VOL(:,24),19));
if (F_PA_Predicted2 >= 5.506563)
    p(9)=1;
    
elseif(F_PA_Predicted2 <= 1.939793)
    p(9)=-1;
end

% Formula:
% Predicted = (((-2.011613) * %chg(VOL_DX,19)) * Eff(HIGH_EC,19)) + ROC(HIGH_DX,6)
% ----------------
% At next bar OPEN_PA:
%   Buy Long if Predicted >= 1.451748
%   Sell Short if Predicted <= -9.810263
F_PA_Predicted3 = (((-2.011613) * Pchg(VOL(:,24),19)) * Eff(HIGH(:,26),19)) + ROCv(HIGH(:,24),6);
if (F_PA_Predicted3 >= 1.451748)
    p(9)=1;
    
elseif(F_PA_Predicted3 <= -9.810263)
    p(9)=-1;
end


% {'CASH','F_NG', 'F_CL', 'F_RU','F_GC',...
%                         'F_US','F_ES','F_RB','F_PA','F_HO',...
%                         'F_FV','F_HG','F_HO','F_PL', 'F_SI',...
%                         'F_KC','F_C','F_CT','F_LB','F_BO',...
%                         'F_OJ','F_AD','F_JY','F_DX','F_CD',...
%                         'F_EC','F_ED','F_SF','F_BP','F_YM',...
%                         'F_NQ'};
%//==========================================================/
%// Little COPER =============================
%//==========================================================/
% Formula:
% Predicted = Sprd(OPEN_HG,CLOSE_HG) - Sprd%(CLOSE_ES,LOW_PL)
% ----------------
% At next bar OPEN_HG:
%   Buy Long if Predicted >= 3.541629
%   Sell Short if Predicted <= -5.90382
F_HG_Predicted1 = Sprd(OPEN(:,12),CLOSE(:,12)) - SprdP(CLOSE(:,7),LOW(:,14));
if (F_HG_Predicted1 >= 3.541629)
    p(12)=1;
elseif(F_HG_Predicted1 <= -5.90382)
    p(12)=-1;
end


%======================================================================================================================================================
% /// END COMMODITY METALS Models==============================
% /// END COMMODITY METALS Models==============================
% /// END COMMODITY METALS Models==============================


%//==========================================================/
%//==========================================================/
%// AGGICULTURE MODELS =============================
%//==========================================================/
%//==========================================================/
% settings.markets     = {'CASH','F_NG', 'F_CL', 'F_RU','F_GC',...
%                         'F_US','F_ES','F_RB','F_PA','F_HO',...
%                         'F_FV','F_HG','F_HO','F_PL', 'F_SI',...
%                         'F_KC','F_C','F_CT','F_LB','F_BO',...
%                         'F_OJ','F_AD','F_JY','F_DX','F_CD',...
%                         'F_EC','F_ED','F_SF','F_BP','F_YM',...
%                         'F_NQ','F_TY', 'T_O', 'F_SB'};

%//==========================================================/
%// COTTON! =============================
%//==========================================================/
% Formula:
% Predicted = Vel(VOL_C,3)
% ----------------
% At next bar OPEN_CT:
%   Buy Long if Predicted >= 5.064608
%   Sell Short if Predicted <= 2.043101
F_CT_Predicted1 = Vel(VOL(:,17),3);
if (F_CT_Predicted1>= 5.064608)
    p(18)=1;
elseif(F_CT_Predicted1  <= 2.043101)
    p(18)=-1;
end

% Formula:
% Predicted = RelStr(VOL_OJ,OI_SB) * Vel(VOL_C,3)
% ----------------
% At next bar OPEN_CT:
%   Buy Long if Predicted >= 9.445773
%   Sell Short if Predicted <= 5.574074
F_CT_Predicted2 = RelStr(VOL(:,21),OI(:,18)) * Vel(VOL(:,17),3);
if (F_CT_Predicted2>= 9.445773)
    p(18)=1;
elseif(F_CT_Predicted2  <= 5.574074)
    p(18)=-1;
end
  

% Formula:
% Predicted = Acc(LOW_O,8)
% ----------------
% At next bar OPEN_CT:
%   Buy Long if Predicted >= 5.117254
%   Sell Short if Predicted <= -3.259947
F_CT_Predicted3 = Acc(LOW(:,33),8);
if (F_CT_Predicted3>= 5.117254)
    p(18)=1;
elseif(F_CT_Predicted3  <= -3.259947)
    p(18)=-1;
end


%//==========================================================/
%// The Sweet Stuff =============================
%//==========================================================/
% Formula:
% Predicted = -(Acc(OI_OJ,39) * (-2.425577))
% ----------------
% At next bar OPEN_SB:
%   Buy Long if Predicted >= 3.863069
%   Sell Short if Predicted <= -5.17163
% F_SB_Predicted1=  -(Acc(OI(:,21),39) * (-2.425577));
% if (F_SB_Predicted1>= 3.863069)
%     p(34)=.5;
% elseif(F_SB_Predicted1  <= -5.17163)
%     p(34)=-.5;
% end
% % Formula:
% % Predicted = ((Mom(HIGH_SB,47) + sin(9.171807)) / Sprd%(VOL_BO,HIGH_OJ)) - Mom(CLOSE_SB,1)
% % ----------------
% % At next bar OPEN_SB:
% %   Buy Long if Predicted >= 4.086589
% %   Sell Short if Predicted <= -2.290361
% F_SB_Predicted2 = ((Mom(HIGH(:,34),47) + sin(9.171807)) / SprdP(VOL(:,20),HIGH(:,21))) - Mom(CLOSE(:,34),1);
% if (F_SB_Predicted2>= 4.086589)
%     p(34)=.5;
% elseif(F_SB_Predicted2  <= -2.290361)
%     p(34)=-.5;
% end
% 
% % Formula:
% % Predicted = (Mom(HIGH_C,42) / Sprd%(VOL_SB,LOW_SB)) - Mom(CLOSE_SB,1)
% % ----------------
% % At next bar OPEN_SB:
% %   Buy Long if Predicted >= 8.850469
% %   Sell Short if Predicted <= -4.140155
% F_SB_Predicted3 = (Mom(HIGH(:,17),42) / SprdP(VOL(:,34),LOW(:,34))) - Mom(CLOSE(:,34),1);
% if (F_SB_Predicted3>= 8.850469)
%     p(34)=.5;
% elseif(F_SB_Predicted3  <= -4.140155)
%     p(34)=-.5;
% end


%//==========================================================/
%// OATS =============================
%//==========================================================/
% Formula:
% Predicted = RelStr(OI_O,OI_OJ) / cos(Acc(VOL_ES,48))
% ----------------
% At next bar OPEN_O:
%   Buy Long if Predicted >= 9.096099
%   Sell Short if Predicted <= -7.616204
F_O_Predicted1 = RelStr(OI(:,33),OI(:,21)) / cos(Acc(VOL(:,24),48));
if (F_O_Predicted1 >= 9.096099)
    p(33)=1;
elseif(F_O_Predicted1 <= -7.616204)
    p(33)=-1;
end

% Formula:
% Predicted = Mom(VOL_DX,30)
% ----------------
% At next bar OPEN_O:
%   Buy Long if Predicted >= 8.209593
%   Sell Short if Predicted <= 7.473214
% F_O_Predicted2 = Mom(VOL(:,24),30);
% if (F_O_Predicted2 >= 8.209593)
%     p(33)=1;
% elseif(F_O_Predicted2 <=  7.473214)
%     p(33)=-1;
% end

%//==========================================================/
%// LUMBER =============================
%//==========================================================/
% Predicted = (3.108074 * tanh(Sprd(LOW_CT,CLOSE_LB))) - Acc(OI_KC,28)
% ----------------------------------
% At next bar OPEN_LB:
%   Buy Long if Predicted >= 6.700186
%   Sell Short if Predicted <= -1.340896

F_LB_Predicted = (3.108074 * tanh(Sprd(LOW(:,18),CLOSE(:,19)))) - Acc(OI(:,16),28);
if (F_LB_Predicted  >= 6.700186)
    p(19)=1;
elseif(F_LB_Predicted  <= -1.340896)
    p(19)=-1;
end

%
% Predicted = (3.108074 * tanh(Sprd(HIGH_CT,CLOSE_LB))) - Acc(OI_KC,28)
% ----------------------------------
% At next bar OPEN_LB:
%   Buy Long if Predicted >= 7.766916
%   Sell Short if Predicted <= -1.340896
F_LB_Predicted2 = (3.108074 * tanh(Sprd(HIGH(:,18),CLOSE(:,19)))) - Acc(OI(:,16),28);
if (F_LB_Predicted2  >= 7.766916)
    p(19)=1;
elseif(F_LB_Predicted2  <= -1.340896)
    p(19)=-1;
end

%//==========================================================/
%// END LUMBER =============================
%//==========================================================/



%//==========================================================/
%// SOYBEAN OIL =============================
%//==========================================================/
F_BO_Predicted = -Vel(OI(:,19),22);
if(F_BO_Predicted >= 7.064185 && settings.longF_BO==0)
    settings.longF_BO = 1;
    p(20)=2;
end
if(F_BO_Predicted < 7.064185 &&  settings.longF_BO == 1)
    settings.longF_BO = 0;
    p(20)=0;
end
if(F_BO_Predicted  <= -6.995482 && settings.shortF_BO == 0)
    settings.shortF_BO = 1;
    p(20)=-2;
end
if(F_BO_Predicted > -6.995482&& settings.shortF_BO == 1)
    settings.shortF_BO = 0;
    p(20)=0;
end
%//==========================================================/
%//==========================================================/
F_BO_Predicted2 = SlopeV(OI(:,16),26) * SprdP(OPEN(:,20),VOL(:,20));
if(F_BO_Predicted2 >= 6.916357 && settings.longF_BO==0)
    settings.longF_BO = 1;
    p(20)=2;
end
if(F_BO_Predicted2 < 6.916357 &&  settings.longF_BO == 1)
    settings.longF_BO = 0;
    p(20)=0;
end
if(F_BO_Predicted2  <= -7.481116 && settings.shortF_BO == 0)
    settings.shortF_BO = 1;
    p(20)=-2;
end
if(F_BO_Predicted2 > -7.481116&& settings.shortF_BO == 1)
    settings.shortF_BO = 0;
    p(20)=0;
end
%//==========================================================/
%//==========================================================/
F_BO_Predicted3 = Pchg(VOL(:,16),30) - Vel(OI(:,19),15);
if(F_BO_Predicted3 >= -1.893812 && settings.longF_BO==0)
    settings.longF_BO = 1;
    p(20)=2;
end
if(F_BO_Predicted3 < -1.893812 &&  settings.longF_BO == 1)
    settings.longF_BO = 0;
    p(20)=0;
end
if(F_BO_Predicted3  <= -3.812834 && settings.shortF_BO == 0)
    settings.shortF_BO = 1;
    p(20)=-2;
end
if(F_BO_Predicted3 > -3.812834 && settings.shortF_BO == 1)
    settings.shortF_BO = 0;
    p(20)=0;
end

%// END Soybean Oil=============================
%//==========================================================/
%//==========================================================/


%//==========================================================/
%// ORANGE JUICE =============================
%//==========================================================/
%[trendsignallong_OJ,trendsignalshort_OJ ] = StandardMa(CLOSE(:,21));
F_OJ_Predicted1 = ROCv(OPEN(:,16),9) * ((-(-0.1862718)) * Vel(LOW(:,20),1));
if (F_OJ_Predicted1  >= 6.645622)
    p(21)=2;
elseif(F_OJ_Predicted1  <= 2.957411)
    p(21)=-2;
end

%//==========================================================/
%//==========================================================/

F_OJ_Predicted2 = Vel(VOL(:,17),32) * 6.531665;
if(F_OJ_Predicted2 >= 6.243222 && settings.longF_OJ==0)
    settings.longF_OJ = 1;
    p(21)=1;
end
if(F_OJ_Predicted2 < 6.243222 &&  settings.longF_OJ == 1)
    settings.longF_OJ = 0;
    p(21)=0;
end
if(F_OJ_Predicted2 <= -1.48061 && settings.shortF_OJ == 0)
    settings.shortF_OJ = 1;
    p(21)=-1;
end
if(F_OJ_Predicted2 > -1.48061 && settings.shortF_OJ == 1)
    settings.shortF_OJ = 0;
    p(21)=0;
end
%//==========================================================/
%// END ORANGE JUICE =============================
%//==========================================================/
% = {'CASH','F_NG', 'F_CL', 'F_RU','F_GC',...
%                         'F_US','F_ES','F_RB','F_PA','F_HO',...
%                         'F_FV','F_HG','F_HO','F_PL', 'F_SI',...
%                         'F_KC','F_C','F_CT','F_LB','F_BO',...
%                         'F_OJ','F_AD','F_JY','F_DX','F_CD',...
%                         'F_EC','F_ED','F_SF','F_BP','F_YM',...
%                         'F_NQ','F_TY', 'F_O', 'F_SB'};


%//==========================================================/
%// FUCKING COFFEE =============================
%//==========================================================/
% Formula:
% Predicted = (-(1/%chg(OI_EC,16))) - Acc(LOW_KC,28)
% ----------------
% At next bar OPEN_KC:
%   Buy Long if Predicted >= 1.989934
%   Sell Short if Predicted <= -6.288701
% F_KC_Predicted1 =  (-(1/Pchg(OI(:,26),16))) - Acc(LOW(:,16),28);
% if (F_KC_Predicted1  >= 1.989934)
%     p(16)=1;
% elseif(F_KC_Predicted1  <= -6.288701)
%     p(16)=-1;
% end
% 
% 
% % Formula:
% % Predicted = (1/Sprd(OI_DX,LOW_KC)) - Acc(LOW_KC,28)
% % ----------------
% % At next bar OPEN_KC:
% %   Buy Long if Predicted >= 1.989934
% %   Sell Short if Predicted <= -6.288701
% F_KC_Predicted1 =  (1/Sprd(OI(:,24),LOW(:,16))) - Acc(LOW(:,16),28);
% if (F_KC_Predicted1  >= 1.989934)
%     p(16)=1;
% elseif(F_KC_Predicted1  <= -6.288701)
%     p(16)=-1;
% end


%//==========================================================/
%// CORN DOGS =============================
%//==========================================================/

% Formula:
% Predicted = ((Sprd(OI_O,OI_ES) / Vel(HIGH_SB,35)) + 7.801213) * %chg(VOL_C,13)
% ----------------
% At next bar OPEN_C:
%   Buy Long if Predicted >= 2.986879
%   Sell Short if Predicted <= -1.284082
F_C_Predicted1 =  ((Sprd(OI(:,33),OI(:,7)) / Vel(HIGH(:,34),35)) + 7.801213) * Pchg(VOL(:,17),13);
if (F_C_Predicted1  >= 2.986879)
    p(17)=1;
elseif(F_C_Predicted1  <= -1.284082)
    p(17)=-1;
end

% Formula:
% Predicted = ((9.561568 * ((RelStr(OPEN_BO,LOW_O) + Vel(VOL_ES,23)) / Mom(HIGH_O,3))) + Sprd(VOL_CT,OI_OJ)) + %chg(VOL_BO,48)
% ----------------
% At next bar OPEN_C:
%   Buy Long if Predicted >= 3.797194
%   Sell Short if Predicted <= -1.309634
F_C_Predicted2 =  ((9.561568 * ((RelStr(OPEN(:,20),LOW(:,33)) + Vel(VOL(:,7),23))...
    / Mom(HIGH(:,33),3))) + Sprd(VOL(:,18),OI(:,21))) + Pchg(VOL(:,21),48);
if (F_C_Predicted2  >= 3.797194)
    p(17)=1;
elseif(F_C_Predicted2  <= -1.309634)
    p(17)=-1;
end


% Predicted = (((ROC%(LOW_C,50) + Eff(OI_BO,18)) / Sprd%(CLOSE_AD,OPEN_AD)) * 1.576218) - 4.666021
% ----------------------------------
% At next bar OPEN_C:
%   Buy Long if Predicted >= 10
%   Sell Short if Predicted <= -7.493718
F_C_Predicted3 =  (((Proc(LOW(:,17),50) + Eff(OI(:,20),18)) / SprdP(CLOSE(:,22),OPEN(:,22))) * 1.576218) - 4.666021;
if (F_C_Predicted3  >= 10)
    p(17)=1;
elseif(F_C_Predicted3  <= -7.493718)
    p(17)=-1;
end

%//==========================================================/
%// Mother fucking sugar =============================
%//==========================================================/

% Formula:
% Predicted = Vel(OI_CT,1) - (-9.978343)
% ----------------
% At next bar OPEN_SB:
%   Buy Long if Predicted >= 6.810936
%   Sell Short if Predicted <= -2.268506
F_SB_Predicted1 =  Vel(OI(:,18),1) - (-9.978343);
if (F_SB_Predicted1   >= 6.810936)
    p(34)=1;
elseif(F_SB_Predicted1  <= -2.268506)
    p(34)=-1;
end

F_SB_Predicted2 =  Acc(VOL(:,34),1);
if (F_SB_Predicted2   >=  8.040363)
    p(34)=1;
elseif(F_SB_Predicted2  <= -3.149655)
    p(34)=-1;
end
%//==========================================================/
%//==========================================================/
%// CURRENCY MODELS =============================
%//==========================================================/
%//==========================================================/


%//==========================================================/
%// EUR =============================
%//==========================================================/
F_EClongtradescore = 0;
F_ECshorttradescore = 0;


[trendsignallong_EC,trendsignalshort_EC ] = StandardMa(CLOSE(:,2));
% Formula:
% Predicted = %chg(HIGH_AD,8) * Sprd(LOW_CD,OPEN_AD)
% ----------------
% At next bar OPEN_EC:
%   Buy Long if Predicted >= 3.700644
%   Sell Short if Predicted <= -2.575125
F_JY_Predicted1 =  Pchg(HIGH(:,22),8) * Sprd(LOW(:,25),OPEN(:,22));
if (F_JY_Predicted1  >= 3.700644)
    %p(26)=1;
    F_EClongtradescore=F_EClongtradescore+1;
elseif(F_JY_Predicted1  <= -2.575125)
    % p(26)=-1;
    F_ECshorttradescore=F_ECshorttradescore+1;
end

%     Formula:
% Predicted = Mom(OI_ED,1)
% ----------------
% At next bar OPEN_EC:
%   Buy Long if Predicted >= 2.432374
%   Sell Short if Predicted <= -9.332744
F_EC_Predicted1 = Mom(OI(:,27),1);
if (F_EC_Predicted1  >= 2.432374)
    % p(26)=1;
    F_EClongtradescore=F_EClongtradescore+1;
elseif(F_EC_Predicted1  <= -9.332744)
    % p(26)=-1;
    F_ECshorttradescore=F_ECshorttradescore+1;
end


% Formula:
% Predicted = Acc(CLOSE_AD,24)
% ----------------
% At next bar OPEN_EC:
%   Buy Long if Predicted >= 5.22758
%   Sell Short if Predicted <= -6.405962
F_EC_Predicted2 = Acc(CLOSE(:,22),24);
if (F_EC_Predicted2  >= 5.22758)
    p(26)=3.3;
elseif(F_EC_Predicted2  <= -6.405962)
    p(26)=-3.3;
end

% Is there a trade?
if(F_EClongtradescore>1 && trendsignallong_EC)
    p(26)=3.3;
end
if(F_ECshorttradescore>1 && trendsignalshort_EC)
    p(26)=-3.3;
end

%//==========================================================/
%// AUD =============================
%//==========================================================/
% Formula:
% Predicted = %chg(CLOSE_RU,37) * Mom(HIGH_JY,24)
% ----------------
% At next bar OPEN_AD:
%   Buy Long if Predicted >= 1.814904
%   Sell Short if Predicted <= -0.027161
input1_AD   = 37; 
input2_AD  = 24;  
[trendsignallong_AD,trendsignalshort_AD] = StandardMa(CLOSE(:,22));
F_AD_Predicted =  Pchg(CLOSE(:,4),input1_AD) * Mom(HIGH(:,23),input2_AD);
if (F_AD_Predicted >= 1.814904&& trendsignallong_AD)
    p(22)=1;
    
elseif(F_AD_Predicted  <= -0.027161&&trendsignalshort_AD)
    p(22)=-1;
    
end

%   Formula:
% Predicted = (Mom(LOW_JY,33) / %chg(CLOSE_RU,40)) * 0.2773536
% ----------------
% At next bar OPEN_AD:
%   Buy Long if Predicted >= 1.330323
%   Sell Short if Predicted <= -2.335326
input3_AD   = 33; 
input4_AD  = 40;  
F_AD_Predicted2 =  (Mom(LOW(:,23),input3_AD) / Pchg(CLOSE(:,4),input4_AD)) * 0.2773536;
if (F_AD_Predicted2 >= 1.330323&& trendsignallong_AD)
    p(22)=1;
elseif(F_AD_Predicted2  <= -2.335326&&trendsignalshort_AD)
    p(22)=-1;
end


% Formula:
% Predicted = (%chg(LOW_RU,34) / RelStr(VOL_GC,VOL_SF)) * Mom(HIGH_JY,29)
% ----------------
% At next bar OPEN_AD:
%   Buy Long if Predicted >= 2.149114
%   Sell Short if Predicted <= -0.602077
input5_AD   = 34; 
input6_AD  = 29;  
F_AD_Predicted3 =  (Pchg(LOW(:,4),input5_AD) / RelStr(VOL(:,5),VOL(:,28))) * Mom(HIGH(:,23),input6_AD);
if (F_AD_Predicted3 >=  2.149114&& trendsignallong_AD)
    p(22)=1;
elseif(F_AD_Predicted3  <= -0.602077&&trendsignalshort_AD)
    p(22)=-1;
end



%//==========================================================/
%// CAD =============================
%//==========================================================/
[trendsignallong_CD,trendsignalshort_CD] = StandardMa(CLOSE(:,28));
% Formula:
% Predicted = Sprd(OPEN_SF,CLOSE_SF) - (-Acc(OPEN_SF,2))
% ----------------
% At next bar OPEN_CD:
%   Buy Long if Predicted >= 4.506654
%   Sell Short if Predicted <= -0.411878
input1_CD   = 2; 
F_CD_Predicted1 = Sprd(OPEN(:,28),CLOSE(:,28)) - (-Acc(OPEN(:,28),input1_CD));
if (F_CD_Predicted1 >=  4.506654)%&& trendsignallong_CD)
    p(25)=1;
elseif(F_CD_Predicted1  <= -0.411878)%&&trendsignalshort_CD)
    p(25)=-1;
end
%
% Formula:
% Predicted = sin(%chg(CLOSE_DX,1))
% ----------------
% At next bar OPEN_CD:
%   Buy Long if Predicted >= -0.248935
%   Sell Short if Predicted <= -0.261328
input2_CD   = 1;
F_CD_Predicted2 = sin(Pchg(CLOSE(:,24),input2_CD));
if (F_CD_Predicted2 >=  -0.248935)%&& trendsignallong_CD)
    p(25)=1;
    %BUY CL
elseif(F_CD_Predicted2  <= -0.261328)%&&trendsignalshort_CD)
    p(25)=-1;
    %SELL CL
end


%//==========================================================/
%// GBP =============================
%//==========================================================/
[trendsignallong_BP,trendsignalshort_BP] = StandardMa(CLOSE(:,29));
% Formula:
% Predicted = Vel(OPEN_EC,input1_BP)
% ----------------
% At next bar OPEN_BP:
%   Buy Long if Predicted >= 7.053886
%   Sell Short if Predicted <= -4.101643
input1_BP   = 24; 
F_BP_Predicted1 = Vel(OPEN(:,26),input1_BP);
if (F_BP_Predicted1 >=  7.053886)%&& trendsignallong_CD)
    p(29)=2;
    %BUY CL
elseif(F_BP_Predicted1  <= -4.101643)%&&trendsignalshort_CD)
    p(29)=-2;
    %SELL CL
end
% Formula:
% Predicted = Vel(CLOSE_EC,16) - Vel(VOL_EC,25)
% ----------------
% At next bar OPEN_BP:
%   Buy Long if Predicted >= 2.027575
%   Sell Short if Predicted <= -4.961777
input2_BP   = 16; 
input3_BP   = 25; 
F_BP_Predicted2 = Vel(CLOSE(:,26),input2_BP) - Vel(VOL(:,26),input3_BP);
if (F_BP_Predicted2 >=  7.053886)%&& trendsignallong_BP)
    p(29)=2;
elseif(F_BP_Predicted2  <= -4.101643)%&&trendsignalshort_BP)
    p(29)=-2;
end

% Formula:
% Predicted = (-Mom(CLOSE_SF,9)) * (-6.327994)
% ----------------
% At next bar OPEN_BP:
%   Buy Long if Predicted >= 7.016809
%   Sell Short if Predicted <= 1.463993
input4_BP   = 9; 
F_BP_Predicted3 = (-Mom(CLOSE(:,28),input4_BP)) * (-6.327994);
if (F_BP_Predicted3>= 7.016809)%&& trendsignallong_BP)
    p(29)=2;
elseif(F_BP_Predicted3  <= 1.463993)%&&trendsignalshort_BP)
    p(29)=-2;
end



%//==========================================================/
%// CHF =============================
%//==========================================================/
% Formula:
% Predicted = ROC(HIGH_DX,14) + Vel(LOW_GC,8)
% ----------------
% At next bar OPEN_SF:
%   Buy Long if Predicted >= 6.631619
%   Sell Short if Predicted <= -7.836473
input3_SF   = 14;
input4_SF   = 8; 
F_SF_Predicted2 = ROCv(HIGH(:,24),input3_SF) + Vel(LOW(:,5),input4_SF);
settings.longF_SF = 0;
settings.shortF_SF = 0;
if (F_SF_Predicted2>=  6.631619&& trendsignallong_BP)
    p(28)=1;
elseif(F_SF_Predicted2  <= -7.836473&&trendsignalshort_BP)
    p(28)=-1;
end
% Formula:
% Predicted = Acc(CLOSE_AD,28) -
% ----------------
% At next bar OPEN_SF:
%   Buy Long if Predicted >= 3.122813
%   Sell Short if Predicted <= -5.489142
input5_SF   = 28; 
F_SF_Predicted3 = Acc(CLOSE(:,22),input5_SF) - settings.randomRoot;
settings.chfChaosVar = F_SF_Predicted3;
if (F_SF_Predicted3>= 3.122813&& trendsignallong_BP)
    p(28)=1;
elseif(F_SF_Predicted3  <= -5.489142&&trendsignalshort_BP)
    p(28)=-1;
end

% Formula:
% Predicted = Vel(HIGH_GC,9) * (Eff(HIGH_AD,9) > %chg(LOW_DX,2))
% ----------------
% At next bar OPEN_SF:
%   Buy Long if Predicted >= -3.346519
%   Sell Short if Predicted <= -5.741417
input6_SF   = 9;
input7_SF   = 9; 
input8_SF   = 2; 
F_SF_Predicted4 = Vel(HIGH(:,5),input6_SF) * (Eff(HIGH(:,22),input7_SF) > Pchg(LOW(:,24),input8_SF));
if (F_SF_Predicted4>= 3.122813)%&& trendsignallong_BP)
    p(28)=1;
elseif(F_SF_Predicted4  <= -5.489142)%&&trendsignalshort_BP)
    p(28)=-1;
end

%//==========================================================/
%// USD =============================
%//==========================================================/
% Formula:
% Predicted = (Mom(CLOSE_DX,19) / (Mom(HIGH_PA,19) - Acc(LOW_PA,11))) + (-5.701985)
% ----------------
% At next bar OPEN_DX:
%   Buy Long if Predicted >= -3.740483
%   Sell Short if Predicted <= -6.737961
F_DX_Predicted1 = (Mom(CLOSE(:,24),19) / (Mom(HIGH(:,9),19) - Acc(LOW(:,9),11))) + (-5.701985);
if (F_DX_Predicted1>= -3.740483)%&& trendsignallong_BP)
    p(24)=1;
elseif(F_DX_Predicted1  <= -6.737961)%&&trendsignalshort_BP)
    p(24)=0;
end


% Formula:
% Predicted = tanh(Eff(VOL_ES,27)) + Acc(LOW_PA,4)
% ----------------
% At next bar OPEN_DX:
%   Buy Long if Predicted >= 0.158193
%   Sell Short if Predicted <= -9.209805
F_DX_Predicted2 = tanh(Eff(VOL(:,7),27)) + Acc(LOW(:,9),4);
if (F_DX_Predicted2>= 0.158193)%&& trendsignallong_BP)
    p(24)=1;
elseif(F_DX_Predicted2 <= -9.209805)%&&trendsignalshort_BP)
    p(24)=-1;
end

% Formula:
% Predicted = (cos(sin((7.710315 * (-8.49986)))) * (Sprd(OI_RB,CLOSE_DX) / ROC%(HIGH_DX,36))) + Sprd%(VOL_RB,CLOSE_ES)
% ----------------
% At next bar OPEN_DX:
%   Buy Long if Predicted >= 5.271159
%   Sell Short if Predicted <= -5.89671
F_DX_Predicted3 = (cos(sin((7.710315 * (-8.49986)))) * (Sprd(OI(:,8),CLOSE(:,24)) / Proc(HIGH(:,24),36))) + SprdP(VOL(:,8),CLOSE(:,7));
if (F_DX_Predicted3>= 5.271159)%&& trendsignallong_BP)
    p(24)=1;
elseif(F_DX_Predicted3 <= -5.89671)%&&trendsignalshort_BP)
    p(24)=-1;
end

end
% end
%//==========================================================/
%// END CURRENCY MODELS =============================
%//==========================================================/

    function [masignallong, masignalshort] = StandardMa(data)
        periodLong_out   = 15;
        periodFast_out  = 5;  
        smaLong_out    = sum(data(end-periodLong_out+1:end)) / periodLong_out;
        smaRecent_out  = sum(data(end-periodFast_out+1:end)) / periodFast_out;
        long_out  = smaRecent_out >= smaLong_out;
        masignallong = long_out;
        masignalshort = ~long_out;
    end
%
%   = {'CASH','F_NG', 'F_CL', 'F_RU','F_GC',...
%                         'F_US','F_ES','F_RB','F_PA','F_HO',...
%                         'F_FV','F_HG','F_HO','F_PL', 'F_SI',...
%                         'F_KC','F_C','F_CT','F_LB','F_BO',...
%                         'F_OJ','F_AD','F_JY','F_DX','F_CD',...
%                         'F_EC','F_ED','F_SF','F_BP'};
%
%Common Indicators
    function vout = indicators(vin,mode,varargin)
        %INDICATORS calculates various technical indicators
        %
        % Description
        %     INDICATORS is a technical analysis tool that calculates various
        %     technical indicators.  Technical analysis is the forecasting of
        %     future financial price movements based on an examination of past
        %     price movements.  Most technical indicators require at least 1
        %     variable argument.  If these arguments are not supplied, default
        %     values are used.
        %
        % Syntax
        %     Momentum
        %         cci                  = indicators([hi,lo,cl]      ,'cci'    ,tp_per,md_per,const)
        %         roc                  = indicators(price           ,'roc'    ,period)
        %         rsi                  = indicators(price           ,'rsi'    ,period)
        %         [fpctk,fpctd]        = indicators([hi,lo,cl]      ,'fsto'   ,k,d)
        %         [spctk,spctd]        = indicators([hi,lo,cl]      ,'ssto'   ,k,d)
        %         [fpctk,fpctd,jline]  = indicators([hi,lo,cl]      ,'kdj'    ,k,d)
        %         willr                = indicators([hi,lo,cl]      ,'william',period)
        %         [dn,up,os]           = indicators([hi,lo]         ,'aroon'  ,period)
        %         tsi                  = indicators(cl              ,'tsi'    ,r,s)
        %     Trend
        %         sma                  = indicators(price           ,'sma'    ,period)
        %         ema                  = indicators(price           ,'ema'    ,period)
        %         [macd,signal,macdh]  = indicators(cl              ,'macd'   ,short,long,signal)
        %         [pdi,mdi,adx]        = indicators([hi,lo,cl]      ,'adx'    ,period)
        %         t3                   = indicators(price           ,'t3'     ,period,volfact)
        %     Volume
        %         obv                  = indicators([cl,vo]         ,'obv')
        %         cmf                  = indicators([hi,lo,cl,vo]   ,'cmf'    ,period)
        %         force                = indicators([cl,vo]         ,'force'  ,period)
        %         mfi                  = indicators([hi,lo,cl,vo]   ,'mfi'    ,period)
        %     Volatility
        %         [middle,upper,lower] = indicators(price           ,'boll'   ,period,weight,nstd)
        %         [middle,upper,lower] = indicators([hi,lo,cl]      ,'keltner',emaper,atrmul,atrper)
        %         atr                  = indicators([hi,lo,cl]      ,'atr'    ,period)
        %         vr                   = indicators([hi,lo,cl]      ,'vr'     ,period)
        %         hhll                 = indicators([hi,lo]         ,'hhll'   ,period)
        %     Other
        %         [index,value]        = indicators(price           ,'zigzag' ,moveper)
        %         change               = indicators(price           ,'compare')
        %         [pivot sprt res]     = indicators([dt,op,hi,lo,cl],'pivot'  ,type)
        %         sar                  = indicators([hi,lo]         ,'sar'    ,step,maximum)
        %
        % Arguments
        %     Outputs
        %         cci/roc/rsi/willr/tsi/sma/ema/t3/obv/cmf/force/mfi/atr/change/sar/vr/hhll
        %                 - single output vector
        %         macd/signal/macdh
        %                 - moving average convergence divergence vector/
        %                   signal line/ macd histogram
        %         middle/upper/lower
        %                 - middle/upper/lower band for bollinger bands or keltner
        %                   channels
        %         fpctk/fpctd/spctk/spctd/jline
        %                 - fast/slow percent k/d and the J Line
        %         index/value
        %                 - index and value for each point in zigzag
        %         pivot/sprt/res
        %                 - vectors for pivot point, support lines, resistance
        %                 lines
        %         dn/up/os
        %                 - aroon down/aroon up/aroon oscillator
        %     Inputs
        %         price   - any price vector (e.g. open, high, ...)
        %         dt/op/hi/lo/cl/vo
        %                 - matlab serial date, open/high/low/close price, and volume of data
        %     Mode
        %         Momentum
        %             cci     - Commodity Channel Index
        %             roc     - Rate of Change
        %             rsi     - Relative Strength Index
        %             fsto    - Fast Stochastic Oscillator
        %             ssto    - Slow Stochastic Oscillator
        %             kdj     - KDJ Indicator
        %             william - William's %R
        %             aroon   - Aroon
        %             tsi     - True Strength Index
        %         Trend
        %             sma     - Simple Moving Average
        %             ema     - Exponential Moving Average
        %             macd    - Moving Average Convergence Divergence
        %             adx     - Wildmer's DMI (ADX)
        %             t3      - Triple EMA (Not the same as EMA3)
        %         Volume
        %             obv     - On-Balance Volume
        %             cmf     - Chaikin Money Flow
        %             force   - Force Index
        %             mfi     - Money Flow Index
        %         Volatility
        %             boll    - Bollinger Bands
        %             keltner - Keltner Channels
        %             atr     - Average True Range
        %             vr      - Volatility Ratio
        %             hhll    - Highest High, Lowest Low
        %         Other
        %             zigzag  - ZigZag
        %             compare - relative price compared to first input
        %             pivot   - Pivot Points
        %             sar     - Parabolic SAR (Stop And Reverse)
        %
        %     Variable Arguments
        %         period  - number of periods over which to make calculations
        %         short/long/signal
        %                 - number of periods for short/long/signal for macd
        %         period/weight/nstd
        %                 - number of periods/weight factor/number of standard
        %                   deviations
        %         k/d/j   - number of periods for %K/%D/JLine
        %         r/s     - number of periods for momentum/smoothed momentum
        %         emaper/atrmul/atrper
        %                 - number of periods for ema/atr multiplier/number of
        %                   periods for atr for keltner
        %         tp_per/md_per/const
        %                 - number of periods for true price/number of periods for
        %                   mean deviation/constant for cci
        %         moveper - movement percent for zigzag
        %         type    - string for pivot point method pick one of 's', 'f', 'd'
        %                   which stand for 'standard', 'fibonacci', 'demark'
        %         step/maximum
        %                 - value to add to acceleration factor at each increment
        %                   maximum value acceleration factor can reach
        %         volfact - volume factor for t3
        %
        % Notes
        %     - there are no argument checks
        %     - all prices must be column oriented
        %     - the parabolic sar indicator is not completely correct
        %     - if there is a tie between price points, the aroon indicator uses
        %     the one farthest back
        %     - 2 methods are available to calculate the ema for the tsi
        %     indicator.  Simply uncomment whichever one is desired.
        %     - the t3 indicator uses a different ema than ta-lib
        %     - 3 methods are available to calculate the kdj.  Simply uncomment
        %     whichever one is desired.
        %
        % Example
        %     load disney.mat
        %     vout = indicators([dis_HIGH,dis_LOW,dis_CLOSE],'fsto',14,3);
        %     fpctk = vout(:,1);
        %     fpctd = vout(:,2);
        %     plot(1:length(fpctk),fpctk,'b',1:length(fpctd),fpctd,'g')
        %     title('Fast Stochastics for Disney')
        %
        % Further Information
        %     For an in depth analysis of how many of these technical indicators
        %     work, refer to one of the following websites or Google it.
        %     http://stockcharts.com/
        %     http://www.investopedia.com/
        %     http://www.ta-lib.org/
        %
        
        % Version : 1.1.3 (05/24/2013)
        % Author  : Nate Jensen <- thanks nate!
        % Created : 10/10/2011
        % History :
        %  - v1.0 10/25/2011 : initial release of 21 indicators
        %  - v1.1 03/04/2012 : 23 indicators, fixed date conversion issue
        %  - v1.1.1 03/25/2012 : 24 indicators
        %  - v1.1.2 03/21/2013 : 25 indicators
        %  - v1.1.3 05/24/2013 : 27 indicators, bug fixes
        
        % To Do
        %  - add more indicators
        
        %%% Main Function
        
        % Initialize output vector
        vout = [];
        
        % Number of observations
        observ = size(vin,1);
        
        % Switch between the various modes
        switch lower(mode)
            
            %%% Momentum
            %==========================================================================
            case 'cci'      % Commodity Channel Index
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable Argument Input
                if isempty(varargin)
                    tp_per = 20;
                    md_per = 20;
                    const  = 0.015;
                else
                    tp_per = varargin{1};
                    md_per = varargin{2};
                    const  = varargin{3};
                end
                
                % Typical Price
                tp = (hi+lo+cl)/3;
                
                % Simple moving average of typical price
                smatp = sma(tp,tp_per,observ);
                
                % Sum of the mean absolute deviation
                smad = nan(observ,1);
                cci  = smad;    % preallocate cci
                for i1 = md_per:observ
                    smad(i1) = sum(abs(smatp(i1)-tp(i1-md_per+1:i1)));
                end
                
                % Commodity Channel Index
                i1 = md_per:observ;
                cci(i1) = (tp(i1)-smatp(i1))./(const*smad(i1)/md_per);
                
                % Format Output
                vout = cci;
                
            case 'roc'      % Rate of Change
                % Input Data
                cl = vin;
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 12;
                else
                    period = varargin{1};
                end
                
                % Rate of Change
                roc = nan(observ,1);
                % calculate rate of change
                roc(period+1:observ) = ((cl(period+1:observ)- ...
                    cl(1:observ-period))./cl(1:observ-period))*100;
                
                % Format Output
                vout = roc;
                
            case 'rsi'      % Relative Strength Index
                % Input Data
                cl = vin;
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 14;
                else
                    period = varargin{1};
                end
                
                % Determine how many nans are in the beginning
                nanVals  = isnan(cl);
                firstVal = find(nanVals == 0, 1, 'first');
                numLeadNans = firstVal - 1;
                
                % Create vector of non-nan closing prices
                nnanvin = cl(~isnan(cl));
                
                % Take a diff of the non-nan closing prices
                diffdata    = diff(nnanvin);
                priceChange = abs(diffdata);
                
                % Create '+' Delta vectors and '-' Delta vectors
                advances = priceChange;
                declines = priceChange;
                
                advances(diffdata < 0)  = 0;
                declines(diffdata >= 0) = 0;
                
                % Calculate the RSI of the non-nan closing prices. Ignore first non-nan
                % vin b/c it is a reference point. Take into account any leading nans
                % that may exist in vin vector.
                trsi = nan(size(diffdata, 1)-numLeadNans, 1);
                for i1 = period:size(diffdata, 1)
                    % Gains/losses
                    totalGain = sum(advances((i1 - (period-1)):i1));
                    totalLoss = sum(declines((i1 - (period-1)):i1));
                    
                    % Calculate RSI
                    rs         = totalGain ./ totalLoss;
                    trsi(i1) = 100 - (100 / (1+rs));
                end
                
                % Pre allocate vector taking into account reference value and leading nans.
                % length of vector = length(vin) - # of reference values - # of leading nans
                rsi = nan(size(cl, 1)-1-numLeadNans, 1);
                
                % Populate RSI
                rsi(~isnan(cl(2+numLeadNans:end))) = trsi;
                
                % Format Output
                vout = [nan(numLeadNans+1, 1); rsi];
                
            case 'fsto'     % Fast Stochastic Oscillator
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable Argument Input
                if isempty(varargin)
                    kperiods = 14;
                    dperiods = 3;
                else
                    kperiods = varargin{1};
                    dperiods = varargin{2};
                end
                
                % Fast %K
                fpctk = nan(observ,1);                      % preallocate Fast %K
                llv = zeros(observ,1);                      % preallocate lowest low
                llv(1:kperiods) = min(lo(1:kperiods));      % lowest low of first kperiods
                for i1 = kperiods:observ                    % cycle through rest of data
                    llv(i1) = min(lo(i1-kperiods+1:i1));    % lowest low of previous kperiods
                end
                hhv = zeros(observ,1);                      % preallocate highest high
                hhv(1:kperiods) = max(hi(1:kperiods));      % highest high of first kperiods
                for i1 = kperiods:observ                    % cycle through rest of data
                    hhv(i1) = max(hi(i1-kperiods+1:i1));    % highest high of previous kperiods
                end
                nzero        = find((hhv-llv) ~= 0);
                fpctk(nzero) = ((cl(nzero)-llv(nzero))./(hhv(nzero)-llv(nzero)))*100;
                
                % Fast %D
                fpctd                = nan(size(cl));
                fpctd(~isnan(fpctk)) = ema(fpctk(~isnan(fpctk)),dperiods, ...
                    length(fpctk(~isnan(fpctk))));
                
                % Format Output
                vout = [fpctk,fpctd];
                
            case 'ssto'     % Slow Stochastic Oscillator
                % Input data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable Argument Input
                if isempty(varargin)
                    kperiods = 14;
                    dperiods = 3;
                else
                    kperiods = varargin{1};
                    dperiods = varargin{2};
                end
                
                % Fast %K
                fpctk = nan(observ,1);                      % preallocate Fast %K
                llv = zeros(observ,1);                      % preallocate lowest low
                llv(1:kperiods) = min(lo(1:kperiods));     % lowest low of first kperiods
                for i1 = kperiods:observ                    % cycle through rest of data
                    llv(i1) = min(lo(i1-kperiods+1:i1));   % lowest low of previous kperiods
                end
                hhv = zeros(observ,1);                      % preallocate highest high
                hhv(1:kperiods) = max(hi(1:kperiods));    % highest high of first kperiods
                for i1 = kperiods:observ                    % cycle through rest of data
                    hhv(i1) = max(hi(i1-kperiods+1:i1));  % highest high of previous kperiods
                end
                nzero        = find((hhv-llv) ~= 0);
                fpctk(nzero) = ((cl(nzero)-llv(nzero))./(hhv(nzero)-llv(nzero)))*100;
                
                % Fast %D
                fpctd                = nan(size(cl));
                fpctd(~isnan(fpctk)) = ema(fpctk(~isnan(fpctk)),dperiods, ...
                    length(fpctk(~isnan(fpctk))));
                
                % Slow %K
                spctk = fpctd;
                
                % Slow %D
                spctd = nan(size(cl));
                spctd(~isnan(spctk)) = ema(spctk(~isnan(spctk)),dperiods, ...
                    length(spctk(~isnan(spctk))));
                
                % Format Output
                vout = [spctk,spctd];
                
            case 'kdj'     % KDJ Indicator
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable Argument Input
                if isempty(varargin)
                    kperiods = 14;
                    dperiods = 3;
                    % jperiods = 5;
                else
                    kperiods = varargin{1};
                    dperiods = varargin{2};
                    % jperiods = varargin{3};
                end
                
                % Fast %K
                fpctk = nan(observ,1);                      % preallocate Fast %K
                llv = zeros(observ,1);                      % preallocate lowest low
                llv(1:kperiods) = min(lo(1:kperiods));     % lowest low of first kperiods
                for i1 = kperiods:observ                    % cycle through rest of data
                    llv(i1) = min(lo(i1-kperiods+1:i1));   % lowest low of previous kperiods
                end
                hhv = zeros(observ,1);                      % preallocate highest high
                hhv(1:kperiods) = max(hi(1:kperiods));    % highest high of first kperiods
                for i1 = kperiods:observ                    % cycle through rest of data
                    hhv(i1) = max(hi(i1-kperiods+1:i1));  % highest high of previous kperiods
                end
                nzero        = find((hhv-llv) ~= 0);
                fpctk(nzero) = ((cl(nzero)-llv(nzero))./(hhv(nzero)-llv(nzero)))*100;
                
                % Fast %D
                fpctd                = nan(size(cl));
                fpctd(~isnan(fpctk)) = ema(fpctk(~isnan(fpctk)),dperiods,observ);
                
                % Method # 1:
                jline = 3*fpctk-2*fpctd;
                
                % Method # 2:
                % jline                = nan(size(cl));
                % jline(~isnan(fpctk)) = ema(fpctk(~isnan(fpctk)),jperiods,observ);
                
                % Method # 3:
                % Slow %K
                % spctk = fpctd;
                
                % Slow %D
                % spctd = nan(size(cl));
                % spctd(~isnan(spctk)) = ema(spctk(~isnan(spctk)),dperiods,observ-dperiods+1);
                
                % J Line
                % jline = 3*spctk-2*spctd;
                
                % Format Output
                % vout = [spctk,spctd,jline];
                
                % Format Output
                vout = [fpctk,fpctd,jline];
                
            case 'william'  % William's %R
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 14;
                else
                    period = varargin{1};
                end
                
                % Highest High and Lowest Low
                llv = zeros(observ,1);                      % preallocate lowest low
                llv(1:period) = min(lo(1:period));     % lowest low of first kperiods
                for i1 = period:observ                    % cycle through rest of data
                    llv(i1) = min(lo(i1-period+1:i1));   % lowest low of previous kperiods
                end
                hhv = zeros(observ,1);                      % preallocate highest high
                hhv(1:period) = max(hi(1:period));    % highest high of first kperiods
                for i1 = period:observ                    % cycle through rest of data
                    hhv(i1) = max(hi(i1-period+1:i1));  % highest high of previous kperiods
                end
                
                % Williams %R
                wpctr        = nan(observ,1);
                nzero        = find((hhv-llv) ~= 0);
                wpctr(nzero) = ((hhv(nzero)-cl(nzero))./(hhv(nzero)-llv(nzero))) * -100;
                
                % Format output
                vout = wpctr;
                
            case 'aroon'    % Aroon
                % Input Data
                hi     = vin(:,1);
                lo      = vin(:,2);
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 25;
                else
                    period = varargin{1};
                end
                
                % Cumulative sum of end indices
                % Output looks like:
                % [1 16 31 46 61 76 91 ... ]
                temp_var1 = cumsum([1;(period+1:observ)'-(1:observ-period)'+1]);
                % Vector of moving indices
                % Output looks like:
                % [1 2 3 4 5 2 3 4 5 6 3 4 5 6 7 4 5 6 7 8 ... ]
                temp_var2 = ones(temp_var1(observ-period+1)-1,1);
                temp_var2(temp_var1(1:observ-period)) = 1-period;
                temp_var2(1) = 1;
                temp_var2 = cumsum(temp_var2);
                
                % Days since last n periods high/low
                [~,min_idx] = min(lo(reshape(temp_var2,period+1,observ-period)),[],1);
                [~,max_idx] = max(hi(reshape(temp_var2,period+1,observ-period)),[],1);
                
                % Aroon Down/Up/Oscillator
                aroon_dn = [nan(period,1); ((period-(period+1-min_idx'))/period)*100];
                aroon_up = [nan(period,1); ((period-(period+1-max_idx'))/period)*100];
                aroon_os = aroon_up-aroon_dn;
                
                % Format Output
                vout = [aroon_dn,aroon_up,aroon_os];
                
            case 'tsi' % True Strength Index
                % Input Data
                cl = vin(:,1);
                
                % Variable Argument Input
                if isempty(varargin)
                    slow = 25;
                    fast = 13;
                else
                    slow = varargin{1};
                    fast = varargin{2};
                end
                
                % If the lag is greater than or equal to the number of observations
                if slow >= observ || fast >= observ
                    return
                end
                
                % Momentum
                mtm    = [0; (cl(2:end,1)) - cl(1:end-1,1)];
                absmtm = abs(mtm);
                
                % Calculate the exponential percentage
                k1 = 2/(slow+1);
                k2 = 2/(fast+1);
                
                % Wikipedia method for calculating ema
                % Preallocate
                ema1 = zeros(observ,1);
                ema2 = ema1;
                ema3 = ema1;
                ema4 = ema1;
                
                % EMA's
                for i1 = 2:observ
                    ema1(i1) = k1 * (mtm(i1)-ema1(i1-1))    + ema1(i1-1);
                    ema2(i1) = k2 * (ema1(i1)-ema2(i1-1))   + ema2(i1-1);
                    ema3(i1) = k1 * (absmtm(i1)-ema3(i1-1)) + ema3(i1-1);
                    ema4(i1) = k2 * (ema3(i1)-ema4(i1-1))   + ema4(i1-1);
                end
                
                % True Strength Index
                tsi = 100*ema2./ema4;
                
                %         % Matlab method for calculating ema
                %         % Preallocate EMA's
                %         ema1 = nan(observ,1);
                %         ema2 = ema1;
                %         ema3 = ema1;
                %         ema4 = ema1;
                %
                %         % Calculate the simple moving average for the first 'exp mov avg' value.
                %         ema1(slow) = sum(mtm(1:slow))/slow;
                %         ema3(slow) = sum(absmtm(1:slow))/slow;
                %
                %         % K*vin; 1-k
                %         kvin1 = mtm(slow:observ) * k1;
                %         oneK1 = 1-k1;
                %         kvin3 = absmtm(slow:observ) * k1;
                %         oneK2 = 1-k2;
                %
                %         % First period calculation
                %         ema1(slow) = kvin1(1) + (ema1(slow) * oneK1);
                %         ema3(slow) = kvin3(1) + (ema3(slow) * oneK1);
                %
                %         % Remaining periods calculation
                %         for i1 = slow+1:observ
                %             ema1(i1) = kvin1(i1-slow+1) + (ema1(i1-1) * oneK1);
                %             ema3(i1) = kvin3(i1-slow+1) + (ema3(i1-1) * oneK1);
                %         end
                %
                %         % Calculate the simple moving average for the first 'exp mov avg' value.
                %         ema2(slow+fast-1) = sum(ema1(slow:slow+fast-1))/fast;
                %         ema4(slow+fast-1) = sum(ema3(slow:slow+fast-1))/fast;
                %
                %         % K*vin; 1-k
                %         kvin2 = ema1(slow+fast-1:observ) * k2;
                %         kvin4 = ema3(slow+fast-1:observ) * k2;
                %
                %         % First period calculation
                %         ema2(slow+fast-1) = kvin2(1) + (ema2(slow+fast-1) * oneK2);
                %         ema4(slow+fast-1) = kvin4(1) + (ema4(slow+fast-1) * oneK2);
                %
                %         % Remaining periods calculation
                %         for i1 = slow+fast:observ
                %             ema2(i1) = kvin2(i1-fast-slow+2) + (ema2(i1-1) * oneK2);
                %             ema4(i1) = kvin4(i1-fast-slow+2) + (ema4(i1-1) * oneK2);
                %         end
                %
                %         % True Strength Index
                %         tsi = 100*ema2./ema4;
                
                % Format Output
                vout = tsi;
                
                %--------------------------------------------------------------------------
                
                %%% Trend
                %==========================================================================
            case 'sma'      % Simple Moving Average
                % Input Data
                price = vin;
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 20;
                else
                    period = varargin{1};
                end
                
                % Simple Moving Average
                simmovavg = sma(price,period,observ);
                
                % Format Output
                vout = simmovavg;
                
            case 'ema'      % Exponential Moving Average
                % Input Data
                price = vin;
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 20;
                else
                    period = varargin{1};
                end
                
                % Exponential Moving Average
                expmovavg = ema(price,period,observ);
                
                % Format Output
                vout = expmovavg;
                
            case 'macd'     % Moving Average Convergence Divergence
                % Input Data
                cl  = vin;
                
                % Variable Argument Input
                if isempty(varargin)
                    short  = 12;
                    long   = 26;
                    signal = 9;
                else
                    short  = varargin{1};
                    long   = varargin{2};
                    signal = varargin{3};
                end
                
                % EMA of Long Period
                [ema_lp status] = ema(cl,long,observ);
                if ~status
                    return
                end
                
                % EMA of Short Period
                ema_sp = ema(cl,short,observ);
                
                % MACD
                MACD = ema_sp-ema_lp;
                
                % Signal
                [signal status] = ema(MACD(~isnan(MACD)),signal,observ-long+1);
                if ~status
                    return
                end
                signal = [nan(long-1,1);signal];
                
                % MACD Histogram
                MACD_h = MACD-signal;
                
                % Format Output
                vout = [MACD,signal,MACD_h];
                
            case 'adx'      % Wilder's DMI (ADX)
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable argument input
                if isempty(varargin)
                    period = 14;
                else
                    period = varargin{1};
                end
                
                % True range
                h_m_l = hi-lo;                                   % high - low
                h_m_c = [0;abs(hi(2:observ)-cl(1:observ-1))];  % abs(high - close)
                l_m_c = [0;abs(lo(2:observ)-cl(1:observ-1))];   % abs(low - close)
                tr = max([h_m_l,h_m_c,l_m_c],[],2);                 % true range
                
                % Directional Movement
                h_m_h = hi(2:observ)-hi(1:observ-1);            % high - high
                l_m_l = lo(1:observ-1)-lo(2:observ);              % low - low
                pdm1  = zeros(observ-1,1);                          % preallocate pdm1
                max_h = max(h_m_h,0);
                pdm1(h_m_h > l_m_l) = max_h(h_m_h > l_m_l);         % plus
                mdm1  = zeros(observ-1,1);                          % preallocate mdm1
                max_l = max(l_m_l,0);
                mdm1(l_m_l > h_m_h) = max_l(l_m_l > h_m_h);         % minus
                pdm1 = [nan;pdm1];
                mdm1 = [nan;mdm1];
                
                % Preallocate 14 period tr, pdm, mdm, adx
                tr14  = nan(observ,1);  % 14 period true range
                pdm14 = tr14;           % 14 period plus directional movement
                mdm14 = tr14;           % 14 period minus directional movement
                adx   = tr14;           % average directional index
                
                % Calculate tr14, pdm14, mdm14, pdi14, mdi14, dmx
                tr14(period+1)  = sum(tr(period+1-period+1:period+1));
                pdm14(period+1) = sum(pdm1(period+1-period+1:period+1));
                mdm14(period+1) = sum(mdm1(period+1-period+1:period+1));
                for i1 = period+2:observ
                    tr14(i1)  = tr14(i1-1)-tr14(i1-1)/period+tr(i1);
                    pdm14(i1) = pdm14(i1-1)-pdm14(i1-1)/period+pdm1(i1);
                    mdm14(i1) = mdm14(i1-1)-mdm14(i1-1)/period+mdm1(i1);
                end
                pdi14 = 100*pdm14./tr14;                    % 14 period plus directional indicator
                mdi14 = 100*mdm14./tr14;                    % 14 period minus directional indicator
                dmx   = 100*abs(pdi14-mdi14)./(pdi14+mdi14);% directional movement index
                
                % Average Directional Index
                adx(2*period) = sum(dmx(period+1:2*period))/(2*period-period-1);
                for i1 = 2*period+1:observ
                    adx(i1) = (adx(i1-1)*(period-1)+dmx(i1))/period;
                end
                
                % Format Output
                vout = [pdi14,mdi14,adx];
                
            case 't3'       % T3
                % Input Data
                price = vin;
                
                % Variable Argument Input
                if isempty(varargin)
                    period  = 5;
                    volfact = 0.7;
                else
                    period   = varargin{1};
                    volfact = varargin{2};
                end
                
                % EMA
                ema1 = ema(price,period,observ);
                ema2 = [nan(period,1); ema(ema1(~isnan(ema1)),period,observ-period+1)];
                ema3 = [nan(2*period-1,1); ema(ema2(~isnan(ema2)),period,observ-2*period+1)];
                ema4 = [nan(3*period-1,1); ema(ema3(~isnan(ema3)),period,observ-3*period+1)];
                ema5 = [nan(4*period-1,1); ema(ema4(~isnan(ema4)),period,observ-4*period+1)];
                ema6 = [nan(5*period-1,1); ema(ema5(~isnan(ema5)),period,observ-5*period+1)];
                
                % Constants
                c1 = -(volfact*volfact*volfact);
                c2 = 3*(volfact*volfact-c1);
                c3 = -6*volfact*volfact-3*(volfact-c1);
                c4 = 1+3*volfact-c1+3*volfact*volfact;
                
                % T3
                t3 = c1*ema6+c2*ema5+c3*ema4+c4*ema3;
                
                % Format Output
                vout = t3;
                
                %--------------------------------------------------------------------------
                
                %%% Volume
                %==========================================================================
            case 'obv'      % On-Balance Volume
                % Input data
                cl = vin(:,1);
                vo = vin(:,2);
                
                % On-Balance Volume
                obv = vo;
                for i1 = 2:observ
                    if     cl(i1) > cl(i1-1)
                        obv(i1) = obv(i1-1)+vo(i1);
                    elseif cl(i1) < cl(i1-1)
                        obv(i1) = obv(i1-1)-vo(i1);
                    elseif cl(i1) == cl(i1-1)
                        obv(i1) = obv(i1-1);
                    end
                end
                
                % Format Output
                vout = obv;
                
            case 'cmf'      % Chaikin Money Flow
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                vo = vin(:,4);
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 20;
                else
                    period = varargin{1};
                end
                
                % Money Flow Multiplier
                mfm = ((cl-lo)-(hi-cl))/(hi-lo);
                
                % Money Flow Volume
                mfv = mfm*vo;
                
                % Chaikin Money Flow
                cmf = nan(observ,1);
                for i1 = period:observ
                    cmf(i1) = sum(mfv(i1-period+1:i1))/sum(vo(i1-period+1:i1));
                end
                
                % Format Output
                vout = cmf;
                
            case 'force'    % Force Index
                % Input Data
                cl = vin(:,1);
                vo = vin(:,2);
                
                % Variable Argument Input
                if isempty(varargin)
                    period = 13;
                else
                    period = varargin{1};
                end
                
                % Force Index
                force = [nan; (cl(2:observ)-cl(1:observ-1)).*vo(2:observ)];
                force = [nan; ema(force(2:observ),period,observ-1)];
                
                % Format Output
                vout = force;
                
            case 'mfi'      % Money Flow Index
                % Input Data
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                vo = vin(:,4);
                
                if isempty(varargin)
                    period = 14;
                else
                    period = varargin{1};
                end
                
                % Typical Price
                tp = (hi+lo+cl)/3;
                
                % Up or Down
                upordn = ones(observ-1,1);
                upordn(tp(2:observ) <= tp(1:observ-1)) = -1;
                
                % Raw Money Flow
                rmf = tp(2:observ).*vo(2:observ);
                
                % Positive Money Flow
                pmf = zeros(observ-1,1);
                pmf(upordn == 1) = rmf(upordn == 1);
                
                % Negative Money Flow
                nmf = zeros(observ-1,1);
                nmf(upordn == -1) = rmf(upordn == -1);
                
                % Cumulative sum of end indices
                % Output looks like:
                % [1 16 31 46 61 76 91 ... ]
                temp_var1 = cumsum([1;(period:observ-1)'-(1:observ-period)'+1]);
                % Vector of moving indices
                % Output looks like:
                % [1 2 3 4 5 2 3 4 5 6 3 4 5 6 7 4 5 6 7 8 ... ]
                temp_var2 = ones(temp_var1(observ-period+1)-1,1);
                temp_var2(temp_var1(1:observ-period)) = 2-period;
                temp_var2(1) = 1;
                temp_var2 = cumsum(temp_var2);
                
                % Money Flow Ratio
                mfr = sum(pmf(reshape(temp_var2,period,observ-period)),1)'./ ...
                    sum(nmf(reshape(temp_var2,period,observ-period)),1)';
                mfr = [nan(period,1); mfr];
                
                % Money Flow Index
                mfi = 100-100./(1+mfr);
                
                % Format Output
                vout = mfi;
                
                %--------------------------------------------------------------------------
                
                %%% Volatility
                %==========================================================================
            case 'boll'     % Bollinger Bands
                % Input data
                cl = vin;
                
                % Variable argument input
                if isempty(varargin)
                    period = 20;
                    weight = 0;
                    nstd   = 2;
                else
                    period = varargin{1};
                    weight = varargin{2};
                    nstd   = varargin{3};
                end
                
                % Create output vectors.
                mid  = nan(size(cl, 1), 1);
                uppr = mid;
                lowr = mid;
                
                % Create weight vector.
                wtsvec = ((1:period).^weight) ./ (sum((1:period).^weight));
                
                % Save the original data and remove NaN's from the data to be processed.
                nnandata = cl(~isnan(cl));
                
                % Calculate middle band moving average using convolution.
                cmid    = conv(nnandata, wtsvec);
                nnanmid = cmid(period:length(nnandata));
                
                % Calculate shift for the upper and lower bands. The shift is a
                % moving standard deviation of the data.
                mstd = nnandata(period:end); % Pre-allocate
                for i1 = period:length(nnandata)
                    mstd(i1-period+1, :) = std(nnandata(i1-period+1:i1));
                end
                
                % Calculate the upper and lower bands.
                nnanuppr = nnanmid + nstd.*mstd;
                nnanlowr = nnanmid - nstd.*mstd;
                
                % Return the values.
                nanVec = nan(period-1,1);
                mid(~isnan(cl))  = [nanVec; nnanmid];
                uppr(~isnan(cl)) = [nanVec; nnanuppr];
                lowr(~isnan(cl)) = [nanVec; nnanlowr];
                
                % Format output
                vout = [mid,uppr,lowr];
                
            case 'keltner'  % Keltner Channels
                % Input data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable argument input
                if isempty(varargin)
                    emaper = 20;
                    atrmul = 2;
                    atrper = 10;
                else
                    emaper = varargin{1};
                    atrmul = varargin{2};
                    atrper = varargin{3};
                end
                
                % True range
                h_m_l = hi-lo;                                   % high - low
                h_m_c = [0;abs(hi(2:observ)-cl(1:observ-1))];  % abs(high - close)
                l_m_c = [0;abs(lo(2:observ)-cl(1:observ-1))];   % abs(low - close)
                tr = max([h_m_l,h_m_c,l_m_c],[],2);                 % true range
                
                % Average true range
                atr = ema(tr,atrper,observ);
                
                % Middle/Upper/Lower bands of keltner channels
                midd = ema(cl,emaper,observ);
                uppr = midd+atrmul*atr;
                lowr = midd-atrmul*atr;
                
                % Format output
                vout = [midd,uppr,lowr];
                
            case 'atr'      % Average True Range
                % Input data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable argument input
                if isempty(varargin)
                    period = 20;
                else
                    period = varargin{1};
                end
                
                % True range
                h_m_l = hi-lo;                                   % high - low
                h_m_c = [0;abs(hi(2:observ)-cl(1:observ-1))];  % abs(high - close)
                l_m_c = [0;abs(lo(2:observ)-cl(1:observ-1))];   % abs(low - close)
                tr = max([h_m_l,h_m_c,l_m_c],[],2);                 % true range
                
                % Average true range
                atr = ema(tr,period,observ);
                
                % Format Output
                vout = atr;
                
            case 'vr'       % Volatility Ratio
                % Input data
                hi = vin(:,1);
                lo = vin(:,2);
                cl = vin(:,3);
                
                % Variable argument input
                if isempty(varargin)
                    period = 14;
                else
                    period = varargin{1};
                end
                
                % True range
                h_m_l = hi-lo;                                   % high - low
                h_m_c = [0;abs(hi(2:observ)-cl(1:observ-1))];  % abs(high - close)
                l_m_c = [0;abs(lo(2:observ)-cl(1:observ-1))];   % abs(low - close)
                tr = max([h_m_l,h_m_c,l_m_c],[],2);                 % true range
                
                % Volatility Ratio
                vr = tr./ema(tr,period,observ);
                
                % Format Output
                vout = vr;
                
            case 'hhll'     % Highest High, Lowest Low
                % Input data
                hi = vin(:,1);
                lo = vin(:,2);
                
                % Variable argument input
                if isempty(varargin)
                    period = 20;
                else
                    period = varargin{1};
                end
                
                % Lowest Low
                llv = nan(observ,1);                        % preallocate lowest low
                llv(1:period) = min(lo(1:period));         % lowest low of first kperiods
                for i1 = period:observ                      % cycle through rest of data
                    llv(i1) = min(lo(i1-period+1:i1));     % lowest low of previous kperiods
                end
                
                % Highest High
                hhv = nan(observ,1);                        % preallocate highest high
                hhv(1:period) = max(hi(1:period));        % highest high of first kperiods
                for i1 = period:observ                      % cycle through rest of data
                    hhv(i1) = max(hi(i1-period+1:i1));    % highest high of previous kperiods
                end
                
                % Midpoint
                mp = (hhv+llv)/2;
                
                % Format Output
                vout = [hhv llv mp];
                
                %--------------------------------------------------------------------------
                
                %%% Other
                %==========================================================================
            case 'zigzag'   % ZigZag
                % Input data
                cl = vin;
                
                % Variable argument input
                if isempty(varargin)
                    moveper = 7;
                else
                    moveper = varargin{1};
                end
                
                % Preallocate zigzag
                zigzag = nan(observ,1);
                
                % First zigzag is first data point of input vector
                zigzag(1) = 1;
                
                i1 = 1; % index of input data
                i2 = 1; % index of output vector
                
                % The number of outputs is unknown
                while 1
                    % Find the first value in the input, from the current index to
                    % the number of observations, that has a price movement of
                    % moveper greater or less than the value of current index of
                    % the input and return the index of that value
                    % If all of the following conditions are met, temp_var1 is the
                    % index a zigzag
                    temp_var1 = find(cl(i1:observ) > cl(i1)+cl(i1)*moveper/100 | ...
                        cl(i1:observ) < cl(i1)-cl(i1)*moveper/100,1,'first');
                    
                    % If no value is found
                    if     isempty(temp_var1)
                        % If the current index is less than the number of
                        % observations
                        if i1 < observ
                            % If the current index of the output vector is greater
                            % than 1
                            if i2 > 1
                                % If the value of the input of the last recorded
                                % index is less than the value of the input of the
                                % index 2 recordings ago and there is a value
                                % between the value of the last recorded index and
                                % the number of observations that is less than the
                                % value of the last recorded index
                                if     cl(zigzag(i2)) < cl(zigzag(i2-1)) && ...
                                        min(cl(i1:observ)) < cl(zigzag(i2))
                                    % Find the index of the minimum value that is
                                    % between the index of the last recorded value
                                    % and the number of observations
                                    [~,temp_var1] = min(cl(zigzag(i2):observ));
                                    
                                    % Set the output of the current index equal to
                                    % the previously calculated index
                                    zigzag(i2) = i1+temp_var1-1;
                                    
                                    % The opposite of the previous if statement
                                elseif cl(zigzag(i2)) > cl(zigzag(i2-1)) && ...
                                        max(cl(i1:observ)) > cl(zigzag(i2))
                                    [~,temp_var1] = max(cl(zigzag(i2):observ));
                                    zigzag(i2) = i1+temp_var1-1;
                                    
                                    % The previous 2 statements are not true
                                    % The output vector is complete
                                else
                                    break
                                end
                                
                                % The previous statement is not true
                                % The output vector is complete
                            else
                                break
                            end
                            
                            % The previous statement is not true
                            % The output vector is complete
                        else
                            break
                        end
                        
                        % If the current index of the output vector is greater than 1
                    elseif i2 > 1
                        % If the value of the index of temp_var1 is greater than
                        % the value of the last recorded index and the the value of
                        % the last recorded index is greater than the value of the
                        % index 2 recordings ago
                        if     cl(temp_var1+i1-1) > cl(zigzag(i2)) && ...
                                cl(zigzag(i2)) > cl(zigzag(i2-1))
                            % Set the output of the current index equal to the
                            % index temp_var1
                            zigzag(i2) = temp_var1+i1-1;
                            
                            % The opposit of the previous if statement
                        elseif cl(temp_var1+i1-1) < cl(zigzag(i2)) && ...
                                cl(zigzag(i2)) < cl(zigzag(i2-1))
                            zigzag(i2) = temp_var1+i1-1;
                            
                            % If the value of the input of the last recorded index is
                            % less than the value of the input of the index 2
                            % recordings ago and there is a value between the value of
                            % the last recorded index and temp_var1 that is less than
                            % the value of the last recorded index
                        elseif cl(zigzag(i2)) < cl(zigzag(i2-1)) && ...
                                min(cl(zigzag(i2):temp_var1+i1-1)) < cl(zigzag(i2))
                            % Find the index of the minimum value that is between
                            % the index of the last recorded value and temp_var1
                            [~,temp_var1] = min(cl(zigzag(i2):temp_var1+i1-1));
                            
                            % Set the output of the current index equal to the
                            % previously calculated index
                            zigzag(i2) = temp_var1+i1-1;
                            
                            % The opposite of the previous statement
                        elseif cl(zigzag(i2)) > cl(zigzag(i2-1)) && ...
                                max(cl(zigzag(i2):temp_var1+i1-1)) > cl(zigzag(i2))
                            [~,temp_var1] = max(cl(zigzag(i2):temp_var1+i1-1));
                            zigzag(i2) = temp_var1+i1-1;
                            
                            % The previous 4 statements are not true
                        else
                            % Increment the index of the output vector
                            % set the output of the incremented index equal to
                            % temp_var1
                            i2 = i2+1;
                            zigzag(i2) = temp_var1+i1-1;
                        end
                        
                        % The current index of the output is equal to 1
                    else
                        % increment the index of the output vector
                        % set the output of the incremented index equal to
                        % temp_var1
                        i2 = i2+1;
                        zigzag(i2) = temp_var1+i1-1;
                    end
                    
                    % Increment the index of the input data
                    i1 = temp_var1+i1-1;
                end
                
                % Redefine the output data equal to the index of each zigzag, and
                % the value of the index of each zigzag
                zigzag = [zigzag(~isnan(zigzag)),cl(zigzag(~isnan(zigzag)))];
                
                % Format output
                vout = zigzag;
                
            case 'compare'  % Price Comparison
                % Input data
                numvars = size(vin,2);
                price   = vin;
                
                % Percent change relative to first price
                delta_percent = nan(observ,numvars);
                delta_percent(2:observ,:) = 100*(price(2:observ,:)-price(1,:))./price(1,:);
                
                % Format output
                vout = delta_percent;
                
            case 'pivot'        % Pivot Points
                % Input Data
                dt = vin(:,1);
                op = vin(:,2);
                hi = vin(:,3);
                lo = vin(:,4);
                cl = vin(:,5);
                
                % Variable Argument Input
                if isempty(varargin)
                    type = 's';
                else
                    type = varargin{1};
                end
                
                % Convert Matlab time to years, months, and days
                [year,month,day,~,~,~] = datevecmx(dt);
                
                % Frequency
                freq = diff(dt);
                if     sum(freq)/observ < 1 % Intraday
                    freq = day;
                elseif sum(freq)/observ < 7 % Daily
                    freq = month;
                else                        % Weekly/Monthly
                    freq = year;
                end
                
                % Reassign open, high, low, and close based on frequency
                temp_var1 = unique(freq);
                num_dates = length(temp_var1);
                new_open  = nan(observ,1);
                new_high  = nan(observ,1);
                new_low   = nan(observ,1);
                new_close = nan(observ,1);
                for i1 = 2:num_dates
                    last_per = freq == temp_var1(i1-1);
                    this_per = freq == temp_var1(i1);
                    temp_var2 = op(last_per);
                    new_open (this_per) = temp_var2(1);
                    new_high (this_per) = max(hi(last_per));
                    new_low  (this_per) = min(lo(last_per));
                    temp_var2 = cl(last_per);
                    new_close(this_per) = temp_var2(end);
                end
                
                % Pivot Point
                switch type
                    case 's'    % Standard
                        pivot     = (new_high+new_low+new_close)/3;
                        sprt(:,1) = pivot*2-new_high;
                        sprt(:,2) = pivot-(new_high-new_low);
                        res(:,1)  = pivot*2-new_low;
                        res(:,2)  = pivot+new_high-new_low;
                    case 'f'    % Fibonacci
                        pivot     = (new_high+new_low+new_close)/3;
                        sprt(:,1) = pivot-0.382*(new_high-new_low);
                        sprt(:,2) = pivot-0.612*(new_high-new_low);
                        sprt(:,3) = pivot-(new_high-new_low);
                        res(:,1) = pivot+0.382*(new_high-new_low);
                        res(:,2) = pivot+0.612*(new_high-new_low);
                        res(:,3) = pivot+(new_high-new_low);
                    case 'd'    % Demark
                        X = nan(observ,1);
                        temp_var1 = new_high+2*new_low+new_close;
                        temp_var2 = 2*new_high+new_low+new_close;
                        temp_var3 = new_high+new_low+2*new_close;
                        X(new_close < new_open)  = temp_var1(new_close < new_open);
                        X(new_close > new_open)  = temp_var2(new_close > new_open);
                        X(new_close == new_open) = temp_var3(new_close == new_open);
                        pivot = X/4;
                        sprt  = X/2-new_high;
                        res   = X/2-new_low;
                end
                
                % Format Ouput
                vout = [pivot sprt res];
                
            case 'sar'      % Parabolic SAR (Stop And Reverse) <- NOT CORRECT
                % Input Data
                hi = vin(:,1);
                lo = vin(:,2);
                
                % Variable Argument Input
                if isempty(varargin)
                    step    = 0.02;
                    maximum = 0.2;
                else
                    step    = varargin{1};
                    maximum = varargin{2};
                end
                af = step;
                
                % Directional Movement
                h_m_h = hi(2)-hi(1);                    % high - high
                l_m_l = lo(1)-lo(2);                      % low - low
                pdm   = 0;                                  % preallocate pdm1
                mdm   = 0;                                  % preallocate mdm1
                max_h = max(h_m_h,0);                       % max high
                max_l = max(l_m_l,0);                       % max low
                pdm(h_m_h > l_m_l) = max_h(h_m_h > l_m_l);  % +DM
                mdm(l_m_l > h_m_h) = max_l(l_m_l > h_m_h);  % -DM
                
                % false is long true is short
                new_dir            = false;
                new_dir(mdm < pdm) = true;
                
                % Defaults
                out_sar       = nan(observ,1);
                ep (new_dir)  = hi(2);
                sar(new_dir)  = lo(1);
                ep (~new_dir) = lo(2);
                sar(~new_dir) = hi(1);
                
                for i1 = 1:observ-1
                    if new_dir
                        % Switch to short if the low penetrates the SAR value
                        if lo(i1+1) <= sar
                            new_dir = false;
                            sar = ep;
                            
                            %                     sar(sar < high(i1))   = high(i1);
                            %                     sar(sar < high(i1+1)) = high(i1+1);
                            
                            out_sar(i1+1) = sar;
                            
                            af = step;
                            ep = lo(i1+1);
                            
                            sar = sar+af*(ep-sar);
                            
                            %                     sar(sar < high(i1))   = high(i1);
                            %                     sar(sar < high(i1+1)) = high(i1+1);
                        else
                            out_sar(i1+1) = sar;
                            
                            af(hi(i1+1) > ep) = af+step;
                            ep(hi(i1+1) > ep) = hi(i1+1);
                            af(af > maximum)    = maximum;
                            
                            sar = sar+af*(ep-sar);
                            
                            %                     sar(sar > low(i1))   = low(i1);
                            %                     sar(sar > low(i1+1)) = low(i1+1);
                        end
                    else
                        % Switch to long if the high penetrates the SAR value
                        if hi(i1+1) >= sar
                            new_dir = true;
                            sar = ep;
                            
                            %                     sar(sar > low(i1))   = low(i1);
                            %                     sar(sar > low(i1+1)) = low(i1+1);
                            
                            out_sar(i1+1) = sar;
                            
                            af = step;
                            ep = hi(i1+1);
                            
                            sar = sar+af*(ep-sar);
                            
                            %                     sar(sar > low(i1))   = low(i1);
                            %                     sar(sar > low(i1+1)) = low(i1+1);
                        else
                            out_sar(i1+1) = sar;
                            
                            af(lo(i1+1) < ep) = af+step;
                            ep(lo(i1+1) < ep) = lo(i1+1);
                            af(af > maximum)   = maximum;
                            
                            sar = sar+af*(ep-sar);
                            
                            %                     sar(sar < high(i1))  = high(i1);
                            %                     sar(sar < high(i1+1)) = high(i1+1);
                        end
                    end
                end
                
                % Format Output
                vout = out_sar;
                %--------------------------------------------------------------------------
                
        end
        
    end

%%% Simple Moving Average
%==========================================================================
    function [vout status] = sma(vin,lag,observ)
        % Set status
        status = 1;
        
        % If the lag is greater than or equal to the number of observations
        if lag >= observ
            % End function, set status
            status = 0;
            return
        end
        
        % Preallocate a vector of nan's
        vout = nan(observ,1);
        
        % Simple moving average
        ma = filter(ones(1,lag)/lag,1,vin);
        
        % Fill in the nan's
        vout(lag:end) = ma(lag:end);
        
    end
%--------------------------------------------------------------------------

%%% Exponential Moving Average
%==========================================================================
    function [vout status] = ema(vin,lag,observ)
        
        % Preallocate output
        vout   = nan(observ,1);
        
        % Set status
        status = 1;
        
        % If the lag is greater than or equal to the number of observations
        if lag >= observ
            status = 0;
            return
        end
        
        % Calculate the exponential percentage
        k = 2/(lag+1);
        
        % Calculate the simple moving average for the first 'exp mov avg' value.
        vout(lag) = sum(vin(1:lag))/lag;
        
        % K*vin; 1-k
        kvin = vin(lag:observ)*k;
        oneK = 1-k;
        
        % First period calculation
        vout(lag) = kvin(1)+(vout(lag)*oneK);
        
        % Remaining periods calculation
        for i1 = lag+1:observ
            vout(i1) = kvin(i1-lag+1)+(vout(i1-1)*oneK);
        end
        
    end
%--------------------------------------------------------------------------

%%% ATR Goodies
%
    function out = ATR(fieldHigh, fieldLow, fieldClose, period)
        tr = TR(fieldHigh,fieldLow,fieldClose);
        out = mean(tr(end-period+1:end,:),1);
    end

    function out = TR(fieldHigh, fieldLow, fieldClose)
        fieldCloseLag = LAG(fieldClose,1);
        
        range1 = fieldHigh - fieldLow;
        range2 = abs(fieldHigh-fieldCloseLag);
        range3 = abs(fieldLow -fieldCloseLag);
        
        out = max(max(range1,range2),range3);
    end

    function out = LAG(field, period)
        nMarkets = size(field,2);
        out = [nan(period,nMarkets); field(1:end-period,:)];
    end


% Super Straight forwars algo for flexible model building

    function out = SlopeV(data,period)
        sumY=0;
        sumXX=0;
        sumXY=0;
        sumX=0.5*period*(period-1.0);
        
        for c = 1:period
            sumY = sumY+(data(end-c));
            sumXX=sumXX+c*c;
            sumXY=sumXY+c*(data(end-c));
        end
        denominator=period*sumXX-sumX*sumX;
        if (denominator~=0)
            numerator=period*sumXY-sumX*sumY;
            slope = -numerator/denominator;
            out= slope;
        else
            out= 0;
        end
    end
%------------------------- % Rate of Change ------------------------
    function out = Proc(data1,period)
        if(data1(end-period)~=0)
            val = data1(end-period);
            out = 100.0 * data1(end) / val;
        else
            out = 0;
        end
        
    end

%------------------------- % Change ------------------------
    function out = Pchg(data1,period)
        val = data1(end-period);
        out = 100*(data1(end)-val)/val;
    end


%------------------------- Spread% ------------------------
    function out = SprdP(data1,data2)
        out = 100*(data1(end)-data2(end))/data1(end);
    end

%------------------------- Spread ------------------------
    function out = Sprd(data1,data2)
        out = data1(end)-data2(end);
    end


% ------------------------- Acceleration ------------------------
    function out = Acc(data,period)
        vel1 = (data(end)-data(end-period))/period;
        var3 = data((end-period))*2;
        vel2 = (data(end-period) - (var3))/period;
        out = (vel1/vel2)/period;
    end


% ------------------------- Efficiency ------------------------
    function out = Eff(data,period)
        direction=abs(data(end)-data(end-period));
        volatility=0;
        for c = 1:period
            volatility = volatility +abs(data(end-c)-data(c+1));
        end
        if(volatility~=0)
            out = direction/volatility;
        else
            out = 0;
        end
        
    end

%/------------------------- Velocity ------------------------
    function out = Vel(data,period)
        val=data(end-period);
        out = (data(end)-val)/period;
    end

%------------------------- Relative Strength ------------------------
    function out = RelStr(data1,data2)
        out = data1(end)/data2(end);
    end

%------------------------- Momentum ------------------------
    function out = Mom(data1,period)
        out = data1(end)-data1(end-period);
    end

%------------------------- Rate Of Change ------------------------
    function out = ROCv(data1,period)
        out = data1(end) / data1(end-period);
    end

%------------------------- VERY BASIC NN Code for these models if needed - simplely trained on the functions below.
% the core of NN's are SOOOO basic. 
% ------------------------
%------------------------- 2 Neurons ------------------------
    function out = n2(x1,x2,x3,x4)
        out = (tanh(x1*x2+x3*x4));
    end
%------------------------- 3 Neurons ------------------------
    function out = n3(x1,x2,x3,x4,x5,x6)
        out = (tanh(x1*x2+x3*x4+x5*x6));
    end

%------------------------- 4 Neurons ------------------------
    function out = n4(x1,x2,x3,x4,x5,x6,x7,x8)
        out = (tanh(x1*x2+x3*x4+x5*x6+x7*x8));
    end
    function out = Sigmoidv(x)
        if(x>50)
            out=50;
        elseif(x<-50)
            out=0;
        else
            out = 1.0 ./ ( 1.0 + exp(-x) );
        end
    end



%--------------------------------------------------------------------------


