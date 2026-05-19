/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * HarmonyOS ArkUI Window Rotation Strategy Decision Model
 * Based on three-layer decision logic: Support rotation or not → Supported orientations → Preferred orientation
 * All auto-rotation strategies are affected by system "rotation lock" switch. Fixed orientation and desktop-following strategies are not affected.
 */

import { window } from '@kit.ArkUI';

// ==================== Type Definitions ====================

// [Start OrientationConfig]
/**
 * Orientation Type (used uniformly for fixed orientation and preferred orientation of auto rotation)
 */
export type WindowOrientationType =
  | 'UNSPECIFIED' // Unspecified (lock current orientation for fixed mode, no preferred orientation for auto rotation)
    | 'PORTRAIT'
    | 'LANDSCAPE'
    | 'PORTRAIT_INVERTED'
    | 'LANDSCAPE_INVERTED';

/**
 * Auto Rotation Range
 */
export type AutoRotateRange =
  | 'LANDSCAPE_ONLY' // Landscape only (including forward and reverse landscape)
    | 'PORTRAIT_ONLY' // Portrait only (including forward and reverse portrait)
    | 'ALL_ORIENTATIONS'; // All orientations (support all directions)

// [StartExclude OrientationConfig]
/**
 * Strategy Detailed Description Interface
 */
export interface OrientationDescription {
  name: string; // Strategy name
  description: string; // Detailed description
  isRestrictedByControlCenter: boolean; // Whether restricted by control center rotation lock
  category: string; // Belonging category
}

/**
 * UI Option Interface for selector display
 */
export interface OrientationOption {
  value: Orientation;
  label: string;
  category: string;
  description: string;
}
// [EndExclude OrientationConfig]
/**
 * Fixed Orientation Configuration
 */
export interface FixedConfig {
  mode: 'fixed';
  orientation?: WindowOrientationType; // Omitted or 'UNSPECIFIED' means lock current orientation
}

/**
 * Auto Rotation Configuration
 */
export interface AutoRotateConfig {
  mode: 'autoRotate';
  range: AutoRotateRange; // Rotation range
  preferred?: WindowOrientationType; // Preferred orientation (valid only when range = 'ALL_ORIENTATIONS')
}

/**
 * Follow Desktop Configuration
 */
export interface FollowDesktopConfig {
  mode: 'followDesktop';
}

/**
 * Union type of window rotation strategy configuration
 */
export type OrientationConfig = FixedConfig | AutoRotateConfig | FollowDesktopConfig;
// [End OrientationConfig]

// ==================== Type Declaration for Nested Constant Objects ====================

/** Interface for fixed orientation preset collection */
export interface FixedPresets {
  UNSPECIFIED: Orientation;
  PORTRAIT: Orientation;
  LANDSCAPE: Orientation;
  PORTRAIT_INVERTED: Orientation;
  LANDSCAPE_INVERTED: Orientation;
}

/** Interface for preferred orientation preset collection under full orientation rotation */
export interface AllPresets {
  UNSPECIFIED: Orientation;
  PORTRAIT: Orientation;
  LANDSCAPE: Orientation;
  PORTRAIT_INVERTED: Orientation;
  LANDSCAPE_INVERTED: Orientation;
}

/** Interface for auto rotation preset collection */
export interface AutoRotatePresets {
  LANDSCAPE_ONLY: Orientation;
  PORTRAIT_ONLY: Orientation;
  ALL_ORIENTATIONS: AllPresets;
}

/** Top-level preset constant interface */
export interface OrientationPresetsType {
  FOLLOW_DESKTOP: Orientation;
  FIXED: FixedPresets;
  AUTO_ROTATE: AutoRotatePresets;
}

// ==================== Preset Constants (Nested Objects) ====================

/**
 * Strategy constants, directly obtain strategy values through chain property access
 *
 * Usage Examples:
 * - Follow desktop: OrientationPresets.FOLLOW_DESKTOP
 * - Fixed portrait: OrientationPresets.FIXED.PORTRAIT
 * - Lock current orientation: OrientationPresets.FIXED.UNSPECIFIED
 * - Auto rotate landscape only: OrientationPresets.AUTO_ROTATE.LANDSCAPE_ONLY
 * - Full auto rotation with portrait preferred: OrientationPresets.AUTO_ROTATE.ALL.PORTRAIT
 */
export const OrientationPresets: OrientationPresetsType = {
  /** Follow desktop (window inherits desktop rotation behavior) */
  FOLLOW_DESKTOP: window.Orientation.FOLLOW_DESKTOP,

  /** Fixed orientation strategies (force keep specified orientation, not affected by control center) */
  FIXED: {
    /** Lock current orientation */
    UNSPECIFIED: window.Orientation.LOCKED,
    /** Fixed forward portrait */
    PORTRAIT: window.Orientation.PORTRAIT,
    /** Fixed forward landscape */
    LANDSCAPE: window.Orientation.LANDSCAPE,
    /** Fixed reverse portrait */
    PORTRAIT_INVERTED: window.Orientation.PORTRAIT_INVERTED,
    /** Fixed reverse landscape */
    LANDSCAPE_INVERTED: window.Orientation.LANDSCAPE_INVERTED,
  },

  /** Auto rotation strategies (affected by control center "rotation lock") */
  AUTO_ROTATE: {
    /** Landscape-only auto rotation (switch between two landscape directions) */
    LANDSCAPE_ONLY: window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED,
    /** Portrait-only auto rotation (switch between two portrait directions) */
    PORTRAIT_ONLY: window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED,
    /** Full orientation rotation (allow all directions and support preferred orientation) */
    ALL_ORIENTATIONS: {
      /** No preferred orientation: fully determined by sensor within restricted full range */
      UNSPECIFIED: window.Orientation.AUTO_ROTATION_UNSPECIFIED,
      /** Prefer portrait */
      PORTRAIT: window.Orientation.USER_ROTATION_PORTRAIT,
      /** Prefer landscape */
      LANDSCAPE: window.Orientation.USER_ROTATION_LANDSCAPE,
      /** Prefer reverse portrait */
      PORTRAIT_INVERTED: window.Orientation.USER_ROTATION_PORTRAIT_INVERTED,
      /** Prefer reverse landscape */
      LANDSCAPE_INVERTED: window.Orientation.USER_ROTATION_LANDSCAPE_INVERTED,
    },
  },
};

// ==================== Core Utility Class ====================

// Internal metadata type
interface OrientationMeta {
  value: Orientation;
  name: string;
  description: string;
  category: string;
  isRestricted: boolean;
}

/**
 * Window Rotation Strategy Helper
 * Provides query, conversion and selection capabilities for all rotation strategies
 */
export class WindowOrientationHelper {
  // Private static metadata list (single data source)
  private static readonly metaList: OrientationMeta[] = [
    // Special Modes
    {
      value: window.Orientation.FOLLOW_DESKTOP,
      name: '跟随桌面',
      description: '窗口继承桌面旋转行为，不受控制中心限制',
      category: '特殊模式',
      isRestricted: false,
    },
    {
      value: window.Orientation.UNSPECIFIED,
      name: '系统默认',
      description: '由系统决定旋转策略，行为不可预测，一般不建议主动使用',
      category: '特殊模式',
      isRestricted: false,
    },

    // Fixed Orientation
    {
      value: window.Orientation.LOCKED,
      name: '锁定当前方向',
      description: '窗口固定在当前屏幕方向，不受控制中心影响',
      category: '固定方向',
      isRestricted: false,
    },
    {
      value: window.Orientation.PORTRAIT,
      name: '固定竖屏',
      description: '窗口始终保持正向竖屏',
      category: '固定方向',
      isRestricted: false,
    },
    {
      value: window.Orientation.LANDSCAPE,
      name: '固定横屏',
      description: '窗口始终保持正向横屏',
      category: '固定方向',
      isRestricted: false,
    },
    {
      value: window.Orientation.PORTRAIT_INVERTED,
      name: '固定反向竖屏',
      description: '窗口始终保持倒置竖屏',
      category: '固定方向',
      isRestricted: false,
    },
    {
      value: window.Orientation.LANDSCAPE_INVERTED,
      name: '固定反向横屏',
      description: '窗口始终保持倒置横屏',
      category: '固定方向',
      isRestricted: false,
    },

    // Restricted Auto Rotation
    {
      value: window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED,
      name: '自动旋转（仅横屏，受限）',
      description: '仅在横屏两个方向间旋转，受控制中心旋转锁定影响',
      category: '自动旋转（受限制）',
      isRestricted: true,
    },
    {
      value: window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED,
      name: '自动旋转（仅竖屏，受限）',
      description: '仅在竖屏两个方向间旋转，受控制中心旋转锁定影响',
      category: '自动旋转（受限制）',
      isRestricted: true,
    },
    {
      value: window.Orientation.AUTO_ROTATION_RESTRICTED,
      name: '自动旋转（全向，受限）',
      description: '允许所有方向旋转，但受控制中心旋转锁定影响',
      category: '自动旋转（受限制）',
      isRestricted: true,
    },
    {
      value: window.Orientation.AUTO_ROTATION_UNSPECIFIED,
      name: '系统优化的自动旋转',
      description: '系统根据设备类型智能决定可旋转的方向，受控制中心旋转锁定影响',
      category: '自动旋转（受限制）',
      isRestricted: true,
    },

    // Preferred Orientation (Restricted)
    {
      value: window.Orientation.USER_ROTATION_PORTRAIT,
      name: '首选竖屏后自动旋转',
      description: '先转到竖屏方向，随后允许全向旋转，受控制中心影响',
      category: '首选方向',
      isRestricted: true,
    },
    {
      value: window.Orientation.USER_ROTATION_LANDSCAPE,
      name: '首选横屏后自动旋转',
      description: '先转到横屏方向，随后允许全向旋转，受控制中心影响',
      category: '首选方向',
      isRestricted: true,
    },
    {
      value: window.Orientation.USER_ROTATION_PORTRAIT_INVERTED,
      name: '首选反向竖屏后自动旋转',
      description: '先转到反向竖屏，随后允许全向旋转，受控制中心影响',
      category: '首选方向',
      isRestricted: true,
    },
    {
      value: window.Orientation.USER_ROTATION_LANDSCAPE_INVERTED,
      name: '首选反向横屏后自动旋转',
      description: '先转到反向横屏，随后允许全向旋转，受控制中心影响',
      category: '首选方向',
      isRestricted: true,
    },

    // Unrestricted Auto Rotation
    {
      value: window.Orientation.AUTO_ROTATION_LANDSCAPE,
      name: '自动旋转（仅横屏，不受限）',
      description: '仅在横屏方向间旋转，不受控制中心限制',
      category: '自动旋转（不受限制）',
      isRestricted: false,
    },
    {
      value: window.Orientation.AUTO_ROTATION_PORTRAIT,
      name: '自动旋转（仅竖屏，不受限）',
      description: '仅在竖屏方向间旋转，不受控制中心限制',
      category: '自动旋转（不受限制）',
      isRestricted: false,
    },
    {
      value: window.Orientation.AUTO_ROTATION,
      name: '自动旋转（全向，不受限）',
      description: '允许所有方向旋转，不受控制中心限制',
      category: '自动旋转（不受限制）',
      isRestricted: false,
    },
  ];
  // Private static Map for fast lookup (initialized via IIFE when class loads)
  private static readonly metaMap: Map<Orientation, OrientationMeta> = (() => {
    const map = new Map<Orientation, OrientationMeta>();
    for (const meta of WindowOrientationHelper.metaList) {
      map.set(meta.value, meta);
    }
    return map;
  })();

  /**
   * Get detailed description object of specified strategy
   */
  static describe(orientation: Orientation): OrientationDescription {
    const meta = WindowOrientationHelper.metaMap.get(orientation);
    if (meta) {
      return {
        name: meta.name,
        description: meta.description,
        isRestrictedByControlCenter: meta.isRestricted,
        category: meta.category,
      };
    }
    return {
      name: '未知策略',
      description: `未定义的策略值: ${orientation}`,
      isRestrictedByControlCenter: false,
      category: '未知',
    };
  }

  /**
   * Get short name of rotation strategy
   */
  static getName(orientation: Orientation): string {
    return WindowOrientationHelper.describe(orientation).name;
  }

  /**
   * Judge whether current strategy is affected by control center rotation lock
   */
  static isRestricted(orientation: Orientation): boolean {
    return WindowOrientationHelper.describe(orientation).isRestrictedByControlCenter;
  }

  /**
   * Get category of rotation strategy
   */
  static getCategory(orientation: Orientation): string {
    return WindowOrientationHelper.describe(orientation).category;
  }

  /**
   * Get all strategy options for UI selector component
   */
  static getAllOptions(): OrientationOption[] {
    return WindowOrientationHelper.metaList.map(meta => ({
      value: meta.value,
      label: meta.name,
      category: meta.category,
      description: meta.description,
    } as OrientationOption));
  }

  /**
   * Expose original preset constant object
   */
  static get presets(): OrientationPresetsType {
    return OrientationPresets;
  }
  /**
   * Fixed orientation strategy selector
   * @param orientation Target orientation, lock current orientation if omitted or set to 'UNSPECIFIED'
   * @returns Orientation enum value
   */
  static fixed(orientation?: WindowOrientationType): Orientation {
    if (!orientation || orientation === 'UNSPECIFIED') {
      return window.Orientation.LOCKED;
    }
    switch (orientation) {
      case 'PORTRAIT':
        return window.Orientation.PORTRAIT;
      case 'LANDSCAPE':
        return window.Orientation.LANDSCAPE;
      case 'PORTRAIT_INVERTED':
        return window.Orientation.PORTRAIT_INVERTED;
      case 'LANDSCAPE_INVERTED':
        return window.Orientation.LANDSCAPE_INVERTED;
      default:
        return window.Orientation.LOCKED;
    }
  }

  /**
   * Follow desktop rotation strategy
   */
  static followDesktop(): Orientation {
    return window.Orientation.FOLLOW_DESKTOP;
  }

  /**
   * Auto rotation strategy selector (restricted by system rotation lock)
   * @param range Valid rotation range
   * @param preferred Preferred orientation (only valid when range = 'ALL_ORIENTATIONS')
   * @returns Orientation enum value
   */
  static autoRotate(range: AutoRotateRange, preferred?: WindowOrientationType): Orientation {
    if (range === 'LANDSCAPE_ONLY') {
      return window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED;
    }
    if (range === 'PORTRAIT_ONLY') {
      return window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED;
    }
    // ALL_ORIENTATIONS
    if (!preferred || preferred === 'UNSPECIFIED') {
      return window.Orientation.AUTO_ROTATION_UNSPECIFIED;
    }
    switch (preferred) {
      case 'PORTRAIT':
        return window.Orientation.USER_ROTATION_PORTRAIT;
      case 'LANDSCAPE':
        return window.Orientation.USER_ROTATION_LANDSCAPE;
      case 'PORTRAIT_INVERTED':
        return window.Orientation.USER_ROTATION_PORTRAIT_INVERTED;
      case 'LANDSCAPE_INVERTED':
        return window.Orientation.USER_ROTATION_LANDSCAPE_INVERTED;
      default:
        return window.Orientation.AUTO_ROTATION_RESTRICTED;
    }
  }

  /**
   * Auto rotation strategy selector (not restricted by system rotation lock)
   * @param range Valid rotation range
   * @returns Orientation enum value
   */
  static autoRotateUnrestricted(range: AutoRotateRange): Orientation {
    switch (range) {
      case 'LANDSCAPE_ONLY':
        return window.Orientation.AUTO_ROTATION_LANDSCAPE;
      case 'PORTRAIT_ONLY':
        return window.Orientation.AUTO_ROTATION_PORTRAIT;
      case 'ALL_ORIENTATIONS':
        return window.Orientation.AUTO_ROTATION;
      default:
      // Unreachable code, only for exhaustive type check
        return window.Orientation.AUTO_ROTATION;
    }
  }
  /**
   * Universal selector: dynamically get strategy by configuration object (type-safe)
   * @param config Rotation strategy configuration object
   * @returns Orientation enum value
   */
  static select(config?: OrientationConfig): Orientation {
    switch (config?.mode) {
      case 'followDesktop':
        return WindowOrientationHelper.followDesktop();
      case 'fixed':
        return WindowOrientationHelper.fixed(config.orientation);
      case 'autoRotate':
        return WindowOrientationHelper.autoRotate(config.range, config.preferred);
      default:
        return window.Orientation.UNSPECIFIED;
    }
  }
}
