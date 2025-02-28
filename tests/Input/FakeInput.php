<?php

/*
 * This file is part of the Webmozarts Console Parallelization package.
 *
 * (c) Webmozarts GmbH <office@webmozarts.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

declare(strict_types=1);

namespace Webmozarts\Console\Parallelization\Input;

use function class_alias;
use const PHP_VERSION_ID;

$sourceClass = PHP_VERSION_ID > 80_000
    ? FakeInput81::class
    : FakeInput74::class;

class_alias($sourceClass, \Webmozarts\Console\Parallelization\Input\FakeInput::class);
