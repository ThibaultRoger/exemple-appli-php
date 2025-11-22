<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class Siren
{
    public function __construct(
        private string $value
    ) {
        $this->assertIsValid($value);
    }

    private function assertIsValid(string $value): void
    {
        if (!preg_match('/^[0-9]{9}$/', $value)) {
            throw new \InvalidArgumentException(sprintf('Invalid SIREN "%s"', $value));
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
