%%%-------------------------------------------------------------------
%%% @author Mateusz Sokol
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. kwi 2018 13:45
%%%-------------------------------------------------------------------
-module(pollution).
-author("Mateusz Sokol").

%% API
-export([main/0]).

-record(monitor, {stationMap}).
-record(station, {name, coords, measureList}).
-record(measurement, {type, val, date}).

main() ->
  M = createMonitor(),
  M1 = addStation(M, "Stat1", {10, 12}),
  M2 = addValue(M1, "Stat1", 1, 1, 10),
  M3 = addValue(M2, "Stat1", 2, 1, 12),
  M4 = addValue(M3, "Stat1", 3, 1, 9),
  M5 = removeValue(M4, "Stat1", 3, 1),
  io:write(maps:get("Stat1", M5#monitor.stationMap)).

createMonitor() -> #monitor{stationMap = #{}}.

%% dodaje do monitora wpis o nowej stacji pomiarowej (nazwa i współrzędne geograficzne), zwraca zaktualizowany monitor;
addStation(#monitor{stationMap = SL}, Name, Coords) ->
  #monitor{stationMap = SL#{Name => #station{name = Name, coords = Coords, measureList = []}}}.

%% dodaje odczyt ze stacji (współrzędne geograficzne lub nazwa stacji, data, typ pomiaru, wartość), zwraca zaktualizowany monitor;
addValue(#monitor{stationMap = SL}, StationName, Date, Type, Value) ->
  M = #measurement{type = Type, date = Date, val = Value},
  #station{name = N, coords = C, measureList = ML} = maps:get(StationName, SL),
  S = #station{name = N, coords = C, measureList = [M | ML]},
  #monitor{stationMap = SL#{StationName => S}}.

%% usuwa odczyt ze stacji (współrzędne geograficzne lub nazwa stacji, data, typ pomiaru), zwraca zaktualizowany monitor;
removeValue(#monitor{stationMap = SM}, StationName, Date, Type) ->
  #station{coords = C, measureList = ML} = maps:get(StationName, SM),
  L1 = lists:filter(fun(#measurement{type = T, date = D}) -> (T /= Type) or (D /= Date) end, ML),
  #monitor{stationMap = SM#{StationName => #station{name = StationName, coords = C, measureList = L1}}}.

%% zwraca wartość pomiaru o zadanym typie, z zadanej daty i stacji;
getOneValue(#monitor{stationMap = SL}, Type, StationName, Date) ->
  #station{measureList = ML} = maps:get(StationName, SL),
  [H | _] = lists:filter(fun(M) when
    (M#measurement.type == Type) and
      (M#measurement.date == Date) -> true; (_) -> false end, ML),
  H#measurement.val.

%% zwraca średnią wartość parametru danego typu z zadanej stacji;
getStationMean(#monitor{stationMap = SL}, Type, StationName) ->
  #station{measureList = ML} = maps:get(StationName, SL),
  L = lists:filter(fun(M) when M#measurement.type == Type -> true; (_) -> false end, ML),
  Len = length(L),
  LSum = lists:foldl(fun(M, Sum) -> M#measurement.val + Sum end, 0, L),
  LSum / Len.

%% zwraca średnią wartość parametru danego typu, danego dnia na wszystkich stacjach;
getDailyMean(#monitor{stationMap = SM}, Type, Date) ->
  SL = maps:to_list(SM),
  {L, Len} = xd(SL, Type, Date),
  L / Len.

xd([], Type, Date) ->
  {0, 0};
xd([{K, {Name, Coords, MeasureList}} | T], Type, Date) ->
  {Sum, Len} = countAvg(MeasureList, Type, Date),
  {Sum1, Len1} = xd(T, Type, Date),
  {Sum + Sum1, Len + Len1}.

countAvg(ML, Type, Date) ->
  R = function(ML, Type, Date),
  {lists:sum(R), length(R)}.

function(#station{measureList = []}, _Type, _Date) ->
  [];
function(#station{measureList = [#measurement{type = Type,
  val = V, date = Date} | T]}, Type, Date) ->
  [V | function(#station{measureList = T}, Type, Date)];
function(#station{measureList = [#measurement{type = _Type,
  val = _V, date = _Date} | T]}, Type, Date) ->
  [function(#station{measureList = T}, Type, Date)].

%%  wyszuka stacje z najniższym zanieczyszczeniem danego typu
getMinimumPollutionStation(#monitor{stationMap = SM}, Type, Date) ->
  SL = maps:to_list(SM),
  findMin(SL, Type, Date, {100000, ""}).

findMin([], _, _, {Min, Stat}) ->
  {Min, Stat};
findMin([#station{name = N, measureList = ML} | T], Type, Date, {Min, Stat}) ->
  V = findMinInStation(ML, Type, Date, 1000000),
  if (V < Min) ->
    findMin(T, Type, Date, {V, N});
    true ->
      findMin(T, Type, Date, {Min, Stat})
  end.

findMinInStation([], _, _, Min) -> Min;
findMinInStation([#measurement{type = Type, val = V, date = Date} | T], Type, Date, Min) when V < Min ->
  findMinInStation(T, Type, Date, V);
findMinInStation([_ | T], Type, Date, Min) -> findMinInStation(T, Type, Date, Min).


%% ----------- Tests ----------

