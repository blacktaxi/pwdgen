'use strict';

import gulp from 'gulp';
import eslint from 'gulp-eslint';
import rimraf from 'gulp-rimraf';
import watch from 'gulp-watch';
import runSequence from 'run-sequence';
import connect from 'gulp-connect';
import child_process from 'child_process';

const paths = {
  build: 'dist',
  elmSrc: 'elm',
  elmBuild: 'elm/dist/elm.js',
  staticSrc: 'static'
};

function exec_(command, callback) {
  child_process.exec(command, (err, stdout, stderr) => {
    console.log(stdout); // eslint-disable-line no-console
    console.log(stderr); // eslint-disable-line no-console
    callback(err);
  });
}

gulp.task('lint', () => {
  return gulp.src(['**/*.js','!node_modules/**', '!elm/elm-stuff/**', `!${paths.build}/**`])
    .pipe(eslint())
    .pipe(eslint.format())
    .pipe(eslint.failAfterError());
});

gulp.task('clean', () => {
  return gulp.src(`${paths.build}/**/*`, { read: false })
    .pipe(rimraf({ force: true }));
});

gulp.task('build:elm-package-install', (cb) => {
  exec_(`cd ${paths.elmSrc} && ./elm-package-install.py`, cb);
});

gulp.task('build:elm-make', (cb) => {
  exec_(`cd ${paths.elmSrc} && ./elm-build`, cb);
});

gulp.task('build:elm-copy-output', () => {
  return gulp.src(paths.elmBuild)
    .pipe(gulp.dest(paths.build))
    .pipe(connect.reload());
});

gulp.task('build:elm-build', (cb) => {
  runSequence('build:elm-make', 'build:elm-copy-output', cb);
});

gulp.task('build:elm', (cb) => {
  runSequence('build:elm-package-install', 'build:elm-build', cb);
});

gulp.task('build:static', () => {
  return gulp.src(`${paths.staticSrc}/**/*`)
    .pipe(gulp.dest(paths.build))
    .pipe(connect.reload());
});

gulp.task('watch', () => {
  watch(`${paths.staticSrc}/**/*`, ['build:static']);
  watch(`${paths.elmSrc}/**/*`, ['build:elm-build']);
});

gulp.task('connect', () => {
  connect.server({
    root: paths.build,
    livereload: true,
    port: 8000
  });
});

gulp.task('build', (cb) => {
  runSequence('clean', ['build:elm', 'build:static', 'build:styl'], cb);
});

gulp.task('dev', (cb) => {
  runSequence('lint', ['connect', 'watch'], cb);
});

gulp.task('default', ['dev']);
