import { formatReservesAndIncentives } from '@aave/math-utils';
import dayjs from 'dayjs';

// `reserves` is from UiPoolDataProvider, `reserveIncentives` is from UiIncentiveDataProvider
const reservesArray = reserves.reservesData;
const baseCurrencyData = reserves.baseCurrencyData;
const reserveIncentives = reserveIncentives.reserveIncentivesArray;
const currentTimestamp = dayjs().unix();

// Formatting reserves data with incentives
const formattedPoolReserves = formatReservesAndIncentives({
  reserves: reservesArray,
  currentTimestamp,
  marketReferenceCurrencyDecimals: baseCurrencyData.marketReferenceCurrencyDecimals,
  marketReferencePriceInUsd: baseCurrencyData.marketReferenceCurrencyPriceInUsd,
  reserveIncentives,
});

// Output formatted pool reserves with incentives
console.log(formattedPoolReserves);
