// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/targets/shader_compiler.dart';
import 'package:flutter_tools/src/devfs.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';

const String fragDir = '/shaders';
const String fragPath = '/shaders/my_shader.frag';
const String notFragPath = '/shaders/not_a_frag.file';
const String outputSpirvPath = '/output/shaders/my_shader.frag.spirv';
const String outputPath = '/output/shaders/my_shader.frag';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fileSystem;
  late Artifacts artifacts;
  late String impellerc;

  setUp(() {
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    impellerc = artifacts.getHostArtifact(HostArtifact.impellerc).path;

    fileSystem.file(impellerc).createSync(recursive: true);
    fileSystem.file(fragPath).createSync(recursive: true);
    fileSystem.file(notFragPath).createSync(recursive: true);
  });

  testWithoutContext('compileShader invokes impellerc for .frag files and sksl target', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        target: ShaderTarget.sksl,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
    expect(fileSystem.file(outputSpirvPath).existsSync(), false);
  });

  testWithoutContext('compileShader invokes impellerc for .frag files and metal ios target', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--metal-ios',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputPath.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        target: ShaderTarget.impelleriOS,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
  });

  testWithoutContext('compileShader invokes impellerc for .frag files and opengl es', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--opengl-es',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputPath.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
        target: ShaderTarget.impellerAndroid,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
  });

  testWithoutContext('compileShader invokes impellerc for non-.frag files', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$notFragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(notFragPath),
        outputPath: outputPath,
        target: ShaderTarget.sksl,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
    expect(fileSystem.file(outputSpirvPath).existsSync(), false);
  });

  testWithoutContext('compileShader throws an exception when impellerc fails', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$notFragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        exitCode: 1,
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await expectLater(
      () => shaderCompiler.compileShader(
        input: fileSystem.file(notFragPath),
        outputPath: outputPath,
        target: ShaderTarget.sksl,
      ),
      throwsA(isA<ShaderCompilerException>()),
    );
    expect(fileSystem.file(outputPath).existsSync(), false);
  });

  testWithoutContext('DevelopmentShaderCompiler can compile for android non-impeller', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=/.tmp_rand0/0.8255140718871702.temp',
          '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        }
      ),
    ]);
    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final DevelopmentShaderCompiler developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android, enableImpeller: false);

    final DevFSContent? content = await developmentShaderCompiler
      .recompileShader(DevFSFileContent(fileSystem.file(fragPath)));

    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv'), isNot(exists));
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp'), isNot(exists));
  });

  testWithoutContext('DevelopmentShaderCompiler can compile for android with impeller', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--opengl-es',
          '--iplr',
          '--sl=/.tmp_rand0/0.8255140718871702.temp',
          '--spirv=/.tmp_rand0/0.8255140718871702.temp.spirv',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv').createSync();
          fileSystem.file('/.tmp_rand0/0.8255140718871702.temp')
            ..createSync()
            ..writeAsBytesSync(<int>[1, 2, 3, 4]);
        }
      ),
    ]);
    fileSystem.file(fragPath).writeAsBytesSync(<int>[1, 2, 3, 4]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );
    final DevelopmentShaderCompiler developmentShaderCompiler = DevelopmentShaderCompiler(
      shaderCompiler: shaderCompiler,
      fileSystem: fileSystem,
      random: math.Random(0),
    );

    developmentShaderCompiler.configureCompiler(TargetPlatform.android, enableImpeller: true);

    final DevFSContent? content = await developmentShaderCompiler
      .recompileShader(DevFSFileContent(fileSystem.file(fragPath)));

    expect(await content!.contentsAsBytes(), <int>[1, 2, 3, 4]);
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp.spirv'), isNot(exists));
    expect(fileSystem.file('/.tmp_rand0/0.8255140718871702.temp'), isNot(exists));
  });
}
