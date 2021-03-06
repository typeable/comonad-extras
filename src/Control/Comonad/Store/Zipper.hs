{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Comonad.Store.Zipper
-- Copyright   :  (C) 2008-2013 Edward Kmett,
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  portable
--
----------------------------------------------------------------------------
module Control.Comonad.Store.Zipper
  ( Zipper, zipper, zipper1, unzipper, size) where

#if !defined(__GLASGOW_HASKELL__) || __GLASGOW_HASKELL__ < 710
import Control.Applicative
#endif
import Control.Comonad (Comonad(..))
import Data.Functor.Extend
import Data.Foldable
import Data.Traversable
import Data.Semigroup.Traversable
import Data.Sequence (Seq)
import qualified Data.Sequence as Seq
import Control.Comonad.Store (ComonadStore(..))
import Data.Maybe (fromJust)

data Zipper t a = Zipper (forall b. Seq b -> t b) {-# UNPACK #-} !Int !(Seq a)

zipper :: Traversable t => t a -> Maybe (Zipper t a)
zipper t = case toList t of
  [] -> Nothing
  xs -> Just (Zipper (refill t) 0 (Seq.fromList xs))
  where refill bs as = snd (mapAccumL (\(a:as') _ -> (as', a)) (toList as) bs)

zipper1 :: Traversable1 t => t a -> Zipper t a
zipper1 = fromJust . zipper

unzipper :: Zipper t a -> t a
unzipper (Zipper t _ s) = t s

size :: Zipper t a -> Int
size (Zipper _ _ s) = Seq.length s

instance ComonadStore Int (Zipper t) where
  pos (Zipper _ i _) = i
  peek j (Zipper _ _ s) = Seq.index s j
  experiment f (Zipper _ i s) = Seq.index s <$> f i

instance Functor (Zipper t) where
  fmap f (Zipper t i s) = Zipper t i (fmap f s)

instance Foldable (Zipper t) where
  foldMap f (Zipper _ _ s) = foldMap f s

instance Traversable (Zipper t) where
  traverse f (Zipper t i s) = Zipper t i <$> traverse f s

instance Extend (Zipper t) where
  extended = extend

instance Comonad (Zipper t) where
  extend f (Zipper t i s) = Zipper t i (Seq.mapWithIndex (\j _ -> f (Zipper t j s)) s)
  extract (Zipper _ i s) = Seq.index s i
