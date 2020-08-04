// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Linq;

    using BenchmarkDotNet.Columns;
    using BenchmarkDotNet.Configs;
    using BenchmarkDotNet.Jobs;
    using BenchmarkDotNet.Loggers;
    using BenchmarkDotNet.Order;
    using BenchmarkDotNet.Running;
    using BenchmarkDotNet.Validators;

    public static class Program
    {
#if BENCHMARK_HARNESS
        public static void Main(string[] args)
        {
            // TODO: config? Use a different value for ArtifactsPath eg
            // "__\harness\TIMESTAMP".
            BenchmarkSwitcher
                .FromAssembly(typeof(Program).Assembly)
                .Run(args, DefaultConfig.Instance.WithLocalSettings());
        }
#else
        public static void Main()
        {
            string artifactsPath = GetArtifactsPath();

            var config = GetCustomConfig(artifactsPath, shortRunJob: true)
                .WithLocalSettings();

            BenchmarkRunner.Run<ComparisonsTests.SelectMany_Join>(config);
        }
#endif

        public static string GetArtifactsPath()
        {
            // Other options:
            // - typeof(Program).Assembly.Location
            // - Process.GetCurrentProcess().MainModule.FileName
            string baseDir = AppContext.BaseDirectory;
            int len = baseDir.LastIndexOf("test\\Performance\\bin", StringComparison.OrdinalIgnoreCase);
            if (len == -1) { throw new NotSupportedException(); }
            return baseDir.Substring(0, len) + "__\\benchmarks";
        }

        public static IConfig WithLocalSettings(this IConfig config)
        {
            var orderer = new DefaultOrderer(
                SummaryOrderPolicy.FastestToSlowest,
                MethodOrderPolicy.Alphabetical);

            return config
                .AddValidator(ExecutionValidator.FailOnError)
                .AddColumn(RankColumn.Roman)
                .AddColumn(BaselineRatioColumn.RatioMean)
                .WithOrderer(orderer);
        }

        // No exporter, less verbose logger.
        public static IConfig GetCustomConfig(string artifactsPath, bool shortRunJob)
        {
            var defaultConfig = DefaultConfig.Instance;

            var config = new ManualConfig();
            config.AddAnalyser(defaultConfig.GetAnalysers().ToArray());
            config.AddColumnProvider(defaultConfig.GetColumnProviders().ToArray());
            config.AddDiagnoser(defaultConfig.GetDiagnosers().ToArray());
            //config.AddExporter(defaultConfig.GetExporters().ToArray());
            config.AddFilter(defaultConfig.GetFilters().ToArray());
            config.AddHardwareCounters(defaultConfig.GetHardwareCounters().ToArray());
            //config.AddJob(defaultConfig.GetJobs().ToArray());
            config.AddLogicalGroupRules(defaultConfig.GetLogicalGroupRules().ToArray());
            //config.AddLogger(defaultConfig.GetLoggers().ToArray());
            config.AddValidator(defaultConfig.GetValidators().ToArray());

            config.UnionRule = ConfigUnionRule.AlwaysUseGlobal;

            if (shortRunJob)
            {
                config.AddJob(Job.ShortRun);
            }

            config.ArtifactsPath = artifactsPath;

            config.AddLogger(new ConsoleLogger_());

            return config;
        }

        private sealed class ConsoleLogger_ : ILogger
        {
            private const ConsoleColor DefaultColor = ConsoleColor.Gray;

            private static readonly Dictionary<LogKind, ConsoleColor> s_ColorSchema
                = new Dictionary<LogKind, ConsoleColor>
                {
                    { LogKind.Default, ConsoleColor.Gray },
                    { LogKind.Error, ConsoleColor.Red },
                    { LogKind.Header, ConsoleColor.Magenta },
                    { LogKind.Help, ConsoleColor.DarkGreen },
                    { LogKind.Hint, ConsoleColor.DarkCyan },
                    { LogKind.Info, ConsoleColor.DarkYellow },
                    { LogKind.Result, ConsoleColor.DarkCyan },
                    { LogKind.Statistic, ConsoleColor.Cyan },
                };

            private static volatile int s_Counter;

            public string Id => nameof(ConsoleLogger_);

            public int Priority => 1;

            public void Write(LogKind logKind, string text)
                => Write(logKind, text, Console.Write);

            public void WriteLine()
                => Console.WriteLine();

            public void WriteLine(LogKind logKind, string text)
                => Write(logKind, text, Console.WriteLine);

            public void Flush() { }

            private void Write(LogKind logKind, string text, Action<string> write)
            {
                // Fragile mais au moins ça supprime la plupart des messages que
                // je ne souhaite pas voir.
                if (logKind == LogKind.Default)
                {
                    Spin();
                    return;
                }

                var colorBefore = Console.ForegroundColor;

                try
                {
                    var color = s_ColorSchema.ContainsKey(logKind)
                        ? s_ColorSchema[logKind]
                        : DefaultColor;

                    if (color != colorBefore
                        && color != Console.BackgroundColor)
                    {
                        Console.ForegroundColor = color;
                    }

                    write(text);
                }
                finally
                {
                    if (colorBefore != Console.ForegroundColor
                        && colorBefore != Console.BackgroundColor)
                    {
                        Console.ForegroundColor = colorBefore;
                    }
                }
            }

            public static void Spin()
            {
                s_Counter++;
                switch (s_Counter % 4)
                {
                    case 0: Console.Write("-"); s_Counter = 0; break;
                    case 1: Console.Write("\\"); break;
                    case 2: Console.Write("|"); break;
                    case 3: Console.Write("/"); break;
                }

                Console.SetCursorPosition(Console.CursorLeft - 1, Console.CursorTop);
            }
        }
    }
}
