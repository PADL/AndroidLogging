//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Android
import CAndroidLogging
import Logging

extension Logger.Level {
  var androidLogPriority: UInt32 {
    switch self {
    case .trace:
      return ANDROID_LOG_VERBOSE.rawValue
    case .debug:
      return ANDROID_LOG_DEBUG.rawValue
    case .info:
      fallthrough
    case .notice:
      return ANDROID_LOG_INFO.rawValue
    case .warning:
      return ANDROID_LOG_WARN.rawValue
    case .error:
      return ANDROID_LOG_ERROR.rawValue
    case .critical:
      return ANDROID_LOG_FATAL.rawValue
    }
  }
}

public struct AndroidLogHandler: LogHandler {
  public var logLevel: Logger.Level = .info
  public var metadataProvider: Logger.MetadataProvider?

  private let label: String

  public init(label: String) {
    self.init(label: label, metadataProvider: nil)
  }

  public init(label: String, metadataProvider: Logger.MetadataProvider?) {
    self.label = label
    self.metadataProvider = metadataProvider
  }

  public func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source: String,
    file: String,
    function: String,
    line: UInt
  ) {
    _ = __android_log_write(
      CInt(level.androidLogPriority),
      label,
      "\(prettyMetadata.map { " \($0)" } ?? "") [\(source)] \(message)"
    )
  }

  private var prettyMetadata: String?
  public var metadata = Logger.Metadata() {
    didSet {
      prettyMetadata = prettify(metadata)
    }
  }

  static func prepareMetadata(
    base: Logger.Metadata,
    provider: Logger.MetadataProvider?,
    explicit: Logger.Metadata?
  ) -> Logger.Metadata? {
    var metadata = base

    let provided = provider?.get() ?? [:]

    guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
      // all per-log-statement values are empty
      return nil
    }

    if !provided.isEmpty {
      metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
    }

    if let explicit = explicit, !explicit.isEmpty {
      metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
    }

    return metadata
  }

  private func prettify(_ metadata: Logger.Metadata) -> String? {
    if metadata.isEmpty {
      return nil
    } else {
      return metadata.lazy.sorted(by: { $0.key < $1.key }).map { "\($0)=\($1)" }
        .joined(separator: " ")
    }
  }

  public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
    get {
      metadata[metadataKey]
    }
    set(newValue) {
      metadata[metadataKey] = newValue
    }
  }
}