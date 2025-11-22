<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class ShareCapital
{
    public function __construct(
        private int|float $value
    ) {
        if ($value < 0) {
            throw new \InvalidArgumentException('Share capital cannot be negative');
        }
    }

    public function value(): int|float
    {
        return $this->value;
    }
}
