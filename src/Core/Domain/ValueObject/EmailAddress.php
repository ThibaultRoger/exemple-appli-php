<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class EmailAddress
{
    public function __construct(
        private string $value
    ) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException(sprintf('Invalid email "%s"', $value));
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
